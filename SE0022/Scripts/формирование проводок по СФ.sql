
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

INSERT INTO
  public.account_move_line
(
 -- id,
 -- create_date,
 -- statement_id,
 company_id,
 currency_id,
 -- date_maturity,
  partner_id,
 -- reconcile_partial_id,
 -- blocked,
 -- analytic_account_id,
 -- create_uid,
  credit,
  debit,
  centralisation,
  journal_id,
  account_id,
 -- reconcile_ref,
  tax_code_id,
  state,
  --debit,
  ref,
  period_id,
 -- write_date,
 -- date_created,
  date,
--  write_uid,
  move_id,
  name,
--  reconcile_id,
  tax_amount,
  product_id,
--  account_tax_id,
  product_uom_id,
  amount_currency,
  quantity,
--  followup_date,
--  followup_line_id,
  ef_id,
  ef_list_id
)
SELECT  -- вставляем сумму без налога
  ail.company_id,
  null::::INTEGER currency_id,
  ail.partner_id,
  CASE WHEN  ai.type = 'out_invoice' THEN ail.price_subtotal * (1-atx.amount)
       WHEN  ai.type = 'in_invoice'  THEN null::::NUMERIC
       WHEN  ai.type = 'out_refund'  THEN null::::NUMERIC
       WHEN  ai.type = 'in_refund'   THEN ail.price_subtotal * (1-atx.amount) END credit,
  CASE WHEN  ai.type = 'out_invoice' THEN null::::NUMERIC
       WHEN  ai.type = 'in_invoice'  THEN ail.price_subtotal * (1-atx.amount)
       WHEN  ai.type = 'out_refund'  THEN ail.price_subtotal * (1-atx.amount)
       WHEN  ai.type = 'in_refund'   THEN null::::NUMERIC END debit,
  'normal' as centralisation,
  ai.journal_id,
  ail.account_id,
  atx.ref_base_code_id tax_code_id,
  'valid' state,
  am.name as ref,
  am.period_id,
  am.date date_,
  am.id,
  ail.name ,
  ail.price_subtotal * (1-atx.amount) tax_amount,
  ail.product_id,
  ail.uos_id,
  0 amount_currency,
  ail.quantity,
  ail.ef_id,
  ail.ef_list_id
FROM public.account_invoice_line ail
inner JOIN public.account_invoice ai on ail.invoice_id = ai.id
left outer join public.account_account_tax_default_rel aatdr on ail.account_id = aatdr.account_id
left outer join public.account_tax atx on aatdr.tax_id=atx.id
left outer join public.account_move am on ail.ef_list_id = am.ef_id
where
--ai.type = 'out_invoice' and
ai.ef_id is not null and ai.ef_id<>0
UNION ALL
SELECT  -- вставляем налог
  ail.company_id,
  null::::INTEGER currency_id,
  ail.partner_id,
  CASE WHEN  ai.type = 'out_invoice' THEN ail.price_subtotal * atx.amount
       WHEN  ai.type = 'in_invoice'  THEN null::::NUMERIC
       WHEN  ai.type = 'out_refund'  THEN null::::NUMERIC
       WHEN  ai.type = 'in_refund'   THEN ail.price_subtotal * atx.amount END credit,
  CASE WHEN  ai.type = 'out_invoice' THEN null::::NUMERIC
       WHEN  ai.type = 'in_invoice'  THEN ail.price_subtotal * atx.amount
       WHEN  ai.type = 'out_refund'  THEN ail.price_subtotal * atx.amount
       WHEN  ai.type = 'in_refund'   THEN null::::NUMERIC END debit,
  'normal' as centralisation,
  ai.journal_id,
  atx.account_paid_id,
  atx.ref_tax_code_id tax_code_id,
  'valid' state,
  am.name as ref,
  am.period_id,
  am.date date_,
  am.id,
  atx.name ,
  ail.price_subtotal * atx.amount tax_amount,
  null::::INTEGER  product_id,
  null::::INTEGER  uos_id,
  0 amount_currency,
  1 quantity,
  ail.ef_id,
  ail.ef_list_id
FROM public.account_invoice_line ail
inner JOIN public.account_invoice ai on ail.invoice_id = ai.id
left outer join public.account_account_tax_default_rel aatdr on ail.account_id = aatdr.account_id
left outer join public.account_tax atx on aatdr.tax_id=atx.id
left outer join public.account_move am on ail.ef_list_id = am.ef_id
where
--ai.type = 'out_invoice' and
ai.ef_id is not null and ai.ef_id<>0
UNION ALL
SELECT  -- вставляем продажу
  ail.company_id,
  null::::INTEGER currency_id,
  ail.partner_id,
  sum(CASE WHEN  ai.type = 'out_invoice' THEN null::::NUMERIC
       WHEN  ai.type = 'in_invoice'  THEN ail.price_subtotal
       WHEN  ai.type = 'out_refund'  THEN ail.price_subtotal
       WHEN  ai.type = 'in_refund'   THEN null::::NUMERIC END) credit,
  sum(CASE WHEN  ai.type = 'out_invoice' THEN ail.price_subtotal
       WHEN  ai.type = 'in_invoice'  THEN null::::NUMERIC
       WHEN  ai.type = 'out_refund'  THEN null::::NUMERIC
       WHEN  ai.type = 'in_refund'   THEN ail.price_subtotal END) debit,
  'normal' as centralisation,
  ai.journal_id,
  ai.account_id,
  NULL::::INTEGER  tax_code_id,
  'valid' state,
  am.name as ref,
  am.period_id,
  am.date date_,
  am.id,
  '/' ,
  null::::NUMERIC tax_amount,
  null::::INTEGER product_id,
  null::::INTEGER uos_id,
  0 amount_currency,
  1 quantity,
  null::::INTEGER ef_id, -- ail.ef_id,
  ail.ef_list_id
FROM public.account_invoice_line ail
inner JOIN public.account_invoice ai on ail.invoice_id = ai.id
left outer join public.account_account_tax_default_rel aatdr on ail.account_id = aatdr.account_id
left outer join public.account_tax atx on aatdr.tax_id=atx.id
left outer join public.account_move am on ail.ef_list_id = am.ef_id
where
--ai.type = 'out_invoice' and
ai.ef_id is not null and ai.ef_id<>0
group by
  ail.company_id,
  ail.partner_id,
  ai.journal_id,
  ai.account_id,
  am.name,
  am.period_id,
  am.date ,
  am.id,
  ail.ef_list_id
;