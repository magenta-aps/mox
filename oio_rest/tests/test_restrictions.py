# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from unittest import TestCase

from mock import patch, MagicMock

from oio_rest.auth import restrictions


class TestRestrictions(TestCase):
    @patch('oio_rest.auth.restrictions.DO_ENABLE_RESTRICTIONS', new=False)
    def test_get_restrictions_disabled(self):
        # Arrange
        # Act
        actual_result = restrictions.get_restrictions('', '', '')

        # Assert
        self.assertIsNone(actual_result)

    @patch('oio_rest.auth.restrictions.DO_ENABLE_RESTRICTIONS', new=True)
    @patch('oio_rest.auth.restrictions.AUTH_RESTRICTION_FUNCTION',
           new='mock_fun')
    @patch('oio_rest.auth.restrictions.import_module')
    def test_get_restrictions(self, mock_import_module):
        # type: (MagicMock) -> None
        # Arrange
        mock_import_module.return_value = auth_module = MagicMock()

        user = 'user'
        object_type = 'obj'
        operation = 'op'

        # Act
        restrictions.get_restrictions(user, object_type, operation)

        # Assert
        auth_module.mock_fun.assert_called_with(user, object_type, operation)

    @patch('oio_rest.auth.restrictions.DO_ENABLE_RESTRICTIONS', new=True)
    @patch('oio_rest.auth.restrictions.import_module')
    def test_get_restrictions_raises_on_attribute_error(self,
                                                        mock_import_module):
        # type: (MagicMock) -> None
        # Arrange
        mock_import_module.side_effect = AttributeError

        user = 'user'
        object_type = 'obj'
        operation = 'op'

        # Act
        with self.assertRaises(AttributeError):
            restrictions.get_restrictions(user, object_type, operation)

    @patch('oio_rest.auth.restrictions.DO_ENABLE_RESTRICTIONS', new=True)
    @patch('oio_rest.auth.restrictions.import_module')
    def test_get_restrictions_raises_on_import_error(self, mock_import_module):
        # type: (MagicMock) -> None
        # Arrange
        mock_import_module.side_effect = ImportError

        user = 'user'
        object_type = 'obj'
        operation = 'op'

        # Act
        with self.assertRaises(ImportError):
            restrictions.get_restrictions(user, object_type, operation)
