INSERT INTO
  public.account_move
(
 -- id,
 -- create_uid,
  partner_id,
  company_id,
--  create_date,
  name,
--  write_uid,
  journal_id,
  state,
  period_id,
--  write_date,
--  narration,
  date,
--  balance,
  ref,
--  to_check
  ef_id
)
SELECT
  partner_id,
  company_id,
  case when number is null then ef_id::::CHARACTER else number END,
  journal_id,
  'posted',
  period_id,
--  id,
  date_invoice,
  name,
  ef_id
FROM
  public.account_invoice
  where ef_id is not null and ef_id<>0 and period_id is not null
  and ef_id not in (select ef_id from public.account_move where ef_id is not null and ef_id<>0) ;




UPDATE
  public.account_invoice ai
SET
  move_id = am.id,
  move_name = '/'
FROM public.account_move am
WHERE ai.ef_id = am.ef_id
;

