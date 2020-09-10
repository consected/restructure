

with datadics as (
  select distinct
    id,
    'Q2' "study",
    variable_name,
    domain,
    field_label,
    field_attributes,
    field_note,
    'q2_datadic' "datadic" 
  from q2_datadic
  
  union
  select distinct
    id,
    'IPA' "study",
    variable_name,
    domain,
    field_label,
    field_attributes,
    field_note,
    'ipa_datadic' "datadic" 
  from ipa_datadic
  
)
select 
    sel.id,
    cb.study,
    cb.variable_name,
    cb.domain,
    cb.field_label,
    replace(cb.field_attributes, ' | ',
'
') field_attributes,
    cb.field_note,
    cb.datadic
from datadics cb
inner join data_requests_selected_attribs sel
on 
  sel.record_id = cb.id 
  and not coalesce(sel.disabled, false) 
  and cb.datadic = sel.record_type
  and sel.data_request_id = :list_id 

where
  sel.id IS NOT NULL
order by 
  cb.study, cb.id;
