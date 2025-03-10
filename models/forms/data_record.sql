{{
  config(
    materialized = 'incremental',
    unique_key='uuid',
    on_schema_change='append_new_columns',
    indexes=[
      {'columns': ['uuid'], 'type': 'hash'},
      {'columns': ['saved_timestamp']},
      {'columns': ['reported']},
      {'columns': ['from_phone']},
      {'columns': ['form']},
      {'columns': ['patient_id']},
      {'columns': ['contact_uuid']},
    ]
  )
}}

SELECT
  _id as uuid,
  saved_timestamp,
  to_timestamp((NULLIF(doc->>'reported_date'::text, ''::text)::bigint / 1000)::double precision) AS reported,
  doc->>'form' as form,
  doc->>'from' as from_phone,

  COALESCE(
      doc->>'patient_id',
      doc->'fields'->>'patient_id',
      doc->'fields'->>'patient_uuid'
  ) AS patient_id,

  COALESCE(
      doc->>'place_id',
      doc->'fields'->>'place_id'
  ) AS place_id,

  doc->'contact'->>'_id' as contact_uuid,

  doc->'fields' as fields
FROM {{ env_var('POSTGRES_SCHEMA') }}.{{ env_var('POSTGRES_TABLE') }}
WHERE
  doc->>'type' = 'data_record'
{% if is_incremental() %}
  AND saved_timestamp >= {{ max_existing_timestamp('saved_timestamp') }}
{% endif %}
