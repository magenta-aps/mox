
--Subtract the second tstzrange from the first tstzrange given. 
create or replace function subtract_tstzrange(rangeA tstzrange , rangeB tstzrange )
returns tstzrange[] as
$$
DECLARE
    result tstzrange[];
    str_tzrange1_inc_excl text;
    str_tzrange2_inc_excl text;
    result_non_cont_part_a tstzrange;
    result_non_cont_part_b tstzrange;
BEGIN


if rangeA && rangeB then

--identify the special case the a subtraction of the ranges, would result in a non continuous range.
                if rangeA @> lower(rangeB) and  rangeA @> upper(rangeB)  
                        and not   --make sure that rangeA @> lower(rangeB) actually holds true, considering inc/exc.   
                            (
                                lower(rangeA)=lower(rangeB) 
                                and lower_inc(rangeB) 
                                and not lower_inc(rangeA) 
                            ) 
                        and not  --make sure that rangeA @> upper(rangeB) actually holds true, considering inc/exc.
                            (
                                upper(rangeA)=upper(rangeB) 
                                and upper_inc(rangeB) 
                                and not upper_inc(rangeA)   
                            )
                then
                    if lower_inc(rangeA) then
                        str_tzrange1_inc_excl:='[';
                        else
                        str_tzrange1_inc_excl:='(';
                    end if;

                     if lower_inc(rangeB) then
                        str_tzrange1_inc_excl:= str_tzrange1_inc_excl || ')';
                        else
                        str_tzrange1_inc_excl:= str_tzrange1_inc_excl || ']';
                    end if;

                    if upper_inc(rangeB) then
                        str_tzrange2_inc_excl:='(';
                        else
                        str_tzrange2_inc_excl:='[';
                    end if;

                     if upper_inc(rangeA) then
                        str_tzrange2_inc_excl:= str_tzrange2_inc_excl || ']';
                        else
                        str_tzrange2_inc_excl:= str_tzrange2_inc_excl || ')';
                    end if;
                        

                    result_non_cont_part_a :=tstzrange(lower(rangeA),lower(rangeB),str_tzrange1_inc_excl);
                    result_non_cont_part_b :=tstzrange(upper(rangeB),upper(rangeA),str_tzrange2_inc_excl);

                    if not isempty(result_non_cont_part_a) then
                        result:=array_append(result,result_non_cont_part_a);
                    end if;
                    
                    if  not isempty(result_non_cont_part_b) then
                        result:=array_append(result,result_non_cont_part_b);
                    end if;    
                        
                else
                        if (not isempty(rangeA-rangeB)) then
                            result[1]:= rangeA-rangeB;
                        end if;
                end if; 

else
    result[1]:=rangeA;

end if;


return result;


END;
$$ LANGUAGE plpgsql IMMUTABLE; 