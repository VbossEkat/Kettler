UPDATE
  public.account_invoice_line ail
SET
  account_id=aa.id,
  company_id=ai.company_id,
  partner_id=ai.partner_id
FROM public.account_invoice ai
INNER JOIN public.account_account aa
	 on ai.company_id = aa.company_id
     AND aa.code = CASE WHEN ai.type = 'in_invoice' THEN '220000' --'purchase'
                        WHEN ai.type = 'out_invoice' THEN '200000' --'sale'
                        WHEN ai.type = 'in_refund' THEN '200000' --'purchase_refund'
                        WHEN ai.type = 'out_refund' THEN '220000' --'sale_refund'
                   END
WHERE ail.invoice_id = ai.id



UPDATE
  public.account_invoice ai1
SET
  journal_id = aj.id ,
  account_id = aa.id,
  period_id = ap.id ,
  commercial_partner_id = CASE WHEN ai.commercial_partner_id is null then ai.partner_id else ai.commercial_partner_id end
FROM public.account_invoice ai
INNER JOIN public.account_period ap
     on  ai.company_id = ap.company_id
     and ai.date_invoice BETWEEN ap.date_start and ap.date_stop
     and not ap.special
INNER JOIN public.account_journal aj
	 on ai.company_id = aj.company_id
     AND aj.type = CASE WHEN ai.type = 'in_invoice' THEN 'purchase'
                        WHEN ai.type = 'out_invoice' THEN 'sale'
                        WHEN ai.type = 'in_refund' THEN 'purchase_refund'
                        WHEN ai.type = 'out_refund' THEN 'sale_refund'
                   END
INNER JOIN public.account_account aa
	 on ai.company_id = aa.company_id
     AND aa.code = CASE WHEN ai.type = 'in_invoice' THEN '120000' --'purchase'
                        WHEN ai.type = 'out_invoice' THEN '110200' --'sale'
                        WHEN ai.type = 'in_refund' THEN '120000' --'purchase_refund'
                        WHEN ai.type = 'out_refund' THEN '110200' --'sale_refund'
                   END
WHERE ai1.id = ai.id