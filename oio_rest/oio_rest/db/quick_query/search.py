# SPDX-FileCopyrightText: 2021- Magenta ApS
# SPDX-License-Identifier: MPL-2.0


from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Union

from more_itertools import flatten

from oio_rest.db import get_connection, to_bool
from oio_rest.db.quick_query.registration_parsing import Attribute, Relation, State, \
    VIRKNING, ValueType

RELATION = 'relation'
REG = 'registrering'

INFINITY = 'infinity'
NINFINITY = '-infinity'


@dataclass
class InfiniteDatetime:
    value: str

    @classmethod
    def from_datetime(cls, value: datetime) -> 'InfiniteDatetime':
        return cls(value.isoformat())

    @classmethod
    def from_date_string(cls, value: str) -> 'InfiniteDatetime':
        """
        allows infinity or isoformat
        :param value:
        :return:
        """
        if value in [NINFINITY, INFINITY]:
            return cls(value=value)

        # ensure valid and consistent format
        return cls(value=datetime.fromisoformat(value).isoformat())

    def __lt__(self, other) -> bool:
        if not isinstance(other, InfiniteDatetime):
            raise TypeError(f'unexpected type {type(other)}')
        if other.value == INFINITY:
            if self.value != INFINITY:
                return True
            else:
                raise ValueError(f'unable to compare 2 infinities: '
                                 f'self={self}, other={other}')

        if other.value == NINFINITY:
            if self.value != NINFINITY:
                return False
            else:
                raise ValueError(f'unable to compare 2 infinities: '
                                 f'self={self}, other={other}')

        # other is not infinity or -infinity
        if self.value == INFINITY:
            return False
        if self.value == NINFINITY:
            return True

        # both at finite
        return datetime.fromisoformat(self.value) < datetime.fromisoformat(other.value)


class SearchQueryBuilder:
    def __init__(self, class_name: str, virkning_fra: Union[datetime, str],
                 virkning_til: Union[datetime, str],
                 uuid: Optional[str] = None,
                 registreret_fra: Optional[Union[datetime, str]] = None,
                 registreret_til: Optional[Union[datetime, str]] = None):
        """
        :param class_name: determines where to query
        :param virkning_fra: mandatory, applies to ALL filters added
        :param virkning_til: mandatory, applies to ALL filters added
        :param uuid: uuid of the object (as obj type is determined by class_name)
        :param registreret_fra: optional, applies to the registrations themselves
        :param registreret_til: optional, applies to the registrations themselves
        """

        if not isinstance(class_name, str):
            raise TypeError(f'unexpected type={type(class_name)}, value={uuid}')
        if not (uuid is None or isinstance(uuid, str)):
            raise TypeError(f'unexpected type={type(uuid)}, value={uuid}')

        self.__class_name = class_name
        self.__uuid = uuid

        # virkning
        self.__virkning_fra, self.__virkning_til = \
            self.__validate_ts_range(virkning_fra, virkning_til)

        # core-containers
        self.__conditions: List[str] = []
        self.__relation_conditions: List[str] = []
        self.__inner_join_tables: List[str] = []

        # eagerly create statement-parts
        self.__reg_table = f'{self.__class_name}_{REG}'
        self.__main_col = f'{self.__reg_table}.{class_name}_id'
        self.__id_col_name = 'id'
        self.__count_col_name = 'count'

        if self.__uuid is not None:
            self.__conditions.append(
                f'{self.__reg_table}.{self.__class_name}_id = \'{self.__uuid}\'')

        # registreret
        self.__handle_registreret_dates(registreret_fra, registreret_til)

    @staticmethod
    def __validate_ts_range(start: Union[datetime, str], end: Union[datetime, str]
                            ) -> Tuple[InfiniteDatetime, InfiniteDatetime]:
        """
        a defensive (type) validation and conversion
        :param start: (candidate) start of range
        :param end: (candidate) end of range
        :return:
        """
        for tmp in [start, end]:
            if not (isinstance(tmp, datetime) or isinstance(tmp, str)):
                raise TypeError(
                    f'expected {datetime} or str, got type={type(tmp)} of value={tmp}')

        if isinstance(start, str):
            start = InfiniteDatetime.from_date_string(start)
        else:
            start = InfiniteDatetime.from_datetime(start)

        if isinstance(end, str):
            end = InfiniteDatetime.from_date_string(end)
        else:
            end = InfiniteDatetime.from_datetime(end)

        if not start < end:  # NOTE: STRICT in-equality is important
            raise ValueError(
                f'start must be smaller than end, got:  start={start}, end={end}')

        return start, end

    @staticmethod
    def __overlap_condition_from_range(fully_qualifying_var_name: str,
                                       start: InfiniteDatetime,
                                       end: InfiniteDatetime) -> str:
        """
        convenient wrapper to produce a postgresql tstzrange overlap-statement

        :param fully_qualifying_var_name: postgresql name_of_table."everything_after",
        ie column + custom-type things
        :param start: start of range
        :param end: end of range
        :return: postgresql condition, suitable to put in a WHERE-clause
        """
        return (f'{fully_qualifying_var_name} && '
                f'tstzrange(\'{start.value}\'::timestamptz, '
                f'\'{end.value}\'::timestamptz)')

    def __handle_registreret_dates(self,
                                   reg_start: Optional[Union[str, datetime]],
                                   reg_end: Optional[Union[str, datetime]]):
        """
        validate, and optionally add conditions
        :param reg_start:
        :param reg_end:
        :return:
        """
        no_start = reg_start is None
        no_end = reg_end is None
        if no_start ^ no_end:  # XOR
            # TODO: Determine old behaviour and replicate it, maybe just:
            # if reg_start is None:
            #     reg_start = NINFINITY
            # if reg_end is None:
            #     reg_end = INFINITY
            raise NotImplementedError(f'unexpected missing registreret date: '
                                      f'registreret_start={reg_start}, '
                                      f'registreret_end={reg_end}')

        col_and_var = f'({self.__reg_table}.{REG}).timeperiod'
        if no_start and no_end:  # no reg requirements, so get will get CURRENT
            self.__conditions.append(f'upper({col_and_var})=\'infinity\'::timestamptz')
            return  # stop early

        reg_start, reg_end = self.__validate_ts_range(reg_start, reg_end)

        # we've got both start and end as datetime
        self.__conditions.append(
            self.__overlap_condition_from_range(
                fully_qualifying_var_name=col_and_var,
                start=reg_start,
                end=reg_end))

    @staticmethod
    def __postgres_comparison_from_typed_value(value: str, type_: ValueType) -> str:
        """
        determines how to convert from a python string with a postgres type to an actual
        postgres statement
        :param value: The value to be compared (as a python string)
        :param type_: The postgres type
        :return: valid postgres of the form '[comparison-operator] [value]'
        """
        if type_ is ValueType.TEXT:
            # always uses case insensitive matching
            return f'ilike \'{value}\''
        elif type_ is ValueType.BOOL:
            parsed_bool = to_bool(value)
            if parsed_bool is None:
                raise ValueError(f'unexpected value {value}')
            return '= ' + ('TRUE' if parsed_bool else 'FALSE')

        raise Exception(f'unexpected type_: {type_}, with associated value {value}')

    def add_attribute(self, attr: Attribute):
        """
        adds a filter to the query (in WHERE-clause, solely 'AND'-filtering)
        internally inner-joins tables as needed
        :param attr: the attribute object specifying a filter
        :return:
        """
        table_name = '_'.join([self.__class_name, 'attr', attr.type])
        if table_name not in self.__inner_join_tables:
            self.__inner_join_tables.append(table_name)

        comparison = self.__postgres_comparison_from_typed_value(value=attr.value,
                                                                 type_=attr.value_type)
        self.__conditions.append(f'{table_name}.{attr.key} {comparison}')

    def add_state(self, state: State):
        """
        adds a filter to the query (in WHERE-clause, solely 'AND'-filtering)
        internally inner-joins tables as needed

        :param state: the state object specifying a filter
        :return:
        """
        table_name = '_'.join([self.__class_name, 'tils', state.key])
        if table_name not in self.__inner_join_tables:
            self.__inner_join_tables.append(table_name)
        self.__conditions.append(f'{table_name}.{state.key} = \'{state.value}\'')

    def add_relation(self, relation: Relation):
        """
        adds a filter to the query (in WHERE-clause, solely 'AND'-filtering)
        internally inner-joins tables as needed

        :param relation: the relation object specifying a filter
        :return:
        """
        table_name = f'{self.__class_name}_{RELATION}'
        if table_name not in self.__inner_join_tables:
            self.__inner_join_tables.append(table_name)
        id_var_name = 'rel_maal_uuid' if relation.id_is_uuid else 'rel_maal_urn'
        base_condition = f"""{table_name}.rel_type = '{relation.type}'
         AND {table_name}.{id_var_name} = '{relation.id}'"""

        if relation.object_type is not None:
            obj_condition = f"{table_name}.objekt_type = '{relation.object_type}'"
            condition = f'{base_condition} AND {obj_condition}'
        else:
            condition = base_condition

        self.__relation_conditions.append('(' + condition + ')')

    def __build_subquery(self):
        """
        This is the cool query, where we actually do stuff with the DB

        :return: a valid postgresql statement (MINUS ";" at the end)
        """

        select_from_stmt = f"""
        SELECT {self.__main_col} as {self.__id_col_name}
        FROM {self.__reg_table}"""

        if self.__relation_conditions:  # overwrite if needed
            select_from_stmt: str = f"""
            SELECT {self.__main_col} as {self.__id_col_name},
                COUNT(DISTINCT {self.__class_name}_{RELATION}.rel_type)
                as {self.__count_col_name}
            FROM {self.__reg_table}"""

        additional_conditions = []  # just to avoid altering state
        inner_join_stmt = ''
        if self.__inner_join_tables:  # add the tables needed
            inner_join_stmt = ' '.join(
                [f"""INNER JOIN {table_name} ON
                 {table_name}.{self.__class_name}_{REG}_id = {self.__reg_table}.id"""
                 for table_name in self.__inner_join_tables])

            # add time-related conditions to EVERY table
            for table_name in self.__inner_join_tables:
                additional_conditions.append(
                    self.__overlap_condition_from_range(
                        fully_qualifying_var_name=f'({table_name}.{VIRKNING}).'
                                                  f'timeperiod',
                        start=self.__virkning_fra, end=self.__virkning_til))

        where_stmt = ''
        # check if ANY conditions
        if self.__conditions or additional_conditions or self.__relation_conditions:
            # add the actual where statement, as it will be non-empty
            used_conditions = []
            if self.__conditions:
                used_conditions += self.__conditions

            if additional_conditions:
                used_conditions += additional_conditions

            if self.__relation_conditions:
                conditions = ' OR '.join(self.__relation_conditions)
                relation_condition_str = f" ({conditions})"
                used_conditions.append(relation_condition_str)

            where_stmt = 'WHERE ' + ' AND '.join(used_conditions)

        # add group by (all the ids)
        non_relation_table = [self.__reg_table] + [x for x in self.__inner_join_tables
                                                   if not x.endswith(RELATION)]
        groubp_by_cols = ', '.join(
            [f'{table_name}.id' for table_name in non_relation_table]
        )
        groupby_stmt = f' GROUP BY {groubp_by_cols}'

        return f'{select_from_stmt} {inner_join_stmt} {where_stmt} {groupby_stmt}'

    def get_query(self) -> str:
        """
        Get a query reflecting the currently added constraints.
        Does not alter state of this object

        FOR MAINTAINERS [how this query works]:
            Relation conditions are special, as ONE relation spans MULTIPLE rows.
            SO, we naively query, and filter our results with the following trick:
            query all rows that match ANY relation condition. Then group by id, and
             COUNT. If the count == number of relation conditions consider it a match!
             If not, only some relation-parameters were matched, so discard.
            Notably, if NO relation conditions are present, ANY result is valid.

        :return: a valid postgresql statement
        """

        select_from_stmt = f"""SELECT DISTINCT sub.{self.__id_col_name}
        FROM ({self.__build_subquery()}) AS sub"""

        where_stmt = ''
        if self.__relation_conditions:
            where_stmt = f"""
            WHERE sub.{self.__count_col_name}={len(self.__relation_conditions)}"""

        return f'{select_from_stmt} {where_stmt};'


def quick_search(class_name: str, uuid: Optional[str], registration: Dict,
                 virkning_fra: Union[datetime, str], virkning_til: Union[datetime, str],
                 registreret_fra: Optional[Union[datetime, str]] = None,
                 registreret_til: Optional[Union[datetime, str]] = None,
                 life_cycle_code=None, user_ref=None, note=None,
                 any_attr_value_arr=None, any_rel_uuid_arr=None,
                 first_result=None, max_results=None) -> Tuple[List[str]]:
    """
    (partial) Implementation of MOX search api against LoRa.
    Returns results (uuids) from LoRa.

    :param class_name: Determines LoRa object type (NotImplemented for every classes)
    :param uuid:
    :param registration:
    :param virkning_fra:
    :param virkning_til:
    :param registreret_fra:
    :param registreret_til:
    :param life_cycle_code: NotImplemented
    :param user_ref: NotImplemented
    :param note: NotImplemented
    :param any_attr_value_arr: NotImplemented
    :param any_rel_uuid_arr: NotImplemented
    :param first_result: NotImplemented
    :param max_results: NotImplemented
    :return: Tuple of 1, containing list of uuids
    """

    # Parse input
    class_name = class_name.lower()
    if class_name not in ['organisationfunktion', 'organisationenhed', 'facet',
                          'bruger', 'klasse']:
        raise NotImplementedError(f'not implemented for {class_name}')

    # Non-implemented search parameters
    if life_cycle_code is not None:
        raise NotImplementedError(
            f'life_cycle_code not implemented. Received value={life_cycle_code}')
    if user_ref is not None:
        raise NotImplementedError(
            f'user_ref not implemented. Received value={user_ref}')
    if note is not None:
        raise NotImplementedError(f'note not implemented. Received value={note}')
    if any_attr_value_arr is not None:
        raise NotImplementedError(
            f'any_attr_value_arr not implemented. Received value={any_attr_value_arr}')
    if any_rel_uuid_arr is not None:
        raise NotImplementedError(
            f'any_rel_uuid_arr not implemented. Received value={any_rel_uuid_arr}')
    if first_result is not None:
        raise NotImplementedError(
            f'first_result not implemented. Received value={first_result}')
    if max_results is not None:
        raise NotImplementedError(
            f'max_results not implemented. Received value={max_results}')

    # parse registration
    attributes = Attribute.parse_registration_attributes(class_name=class_name,
                                                         attributes=registration[
                                                             'attributes'])
    states = State.parse_registration_states(class_name=class_name,
                                             states=registration['states'])
    relations = Relation.parse_registration_relations(class_name=class_name,
                                                      relations=registration[
                                                          'relations'])

    # build query
    qb = SearchQueryBuilder(class_name=class_name, virkning_fra=virkning_fra,
                            virkning_til=virkning_til,
                            uuid=uuid, registreret_fra=registreret_fra,
                            registreret_til=registreret_til)

    for x in attributes:
        qb.add_attribute(x)
    for x in states:
        qb.add_state(x)
    for x in relations:
        qb.add_relation(x)

    sql = qb.get_query()

    # execute query against LoRa
    with get_connection() as conn, conn.cursor() as cursor:
        cursor.execute(sql)
        output = cursor.fetchall()

    return list(flatten(output)),
