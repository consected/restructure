

with datadics as (
  select distinct
    id,
    'Q1' "study",
    variable_name,
    domain,
    field_label,
    field_attributes,
    field_note,
    'q1_datadic' "datadic" 
  from q1_datadic
  
  union
  
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
  and (
    :list_type is NULL 
    and sel.data_request_id = :list_id 
   
    OR 
    :list_type = 'ActivityLog::DataRequestAssignment'
    and sel.data_request_id = (
      select to_record_id from model_references mr
      where from_record_type = :list_type
      and from_record_id = :list_id
      and to_record_type = 'DynamicModel::DataRequest'
      order by id desc
      limit 1
    )
  )

where
  sel.id IS NOT NULL
order by 
  cb.study, cb.id;
