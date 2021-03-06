

CREATE OR REPLACE VIEW public.account_invoice_report(
    id,
    date,
    product_id,
    partner_id,
    country_id,
    payment_term,
    period_id,
    uom_name,
    currency_id,
    journal_id,
    fiscal_position,
    user_id,
    company_id,
    nbr,
    type,
    state,
    categ_id,
    date_due,
    account_id,
    account_line_id,
    partner_bank_id,
    product_qty,
    price_total,
    price_average,
    currency_rate,
    residual,
    commercial_partner_id,
    section_id)
AS
  SELECT sub.id,
         sub.date,
         sub.product_id,
         sub.partner_id,
         sub.country_id,
         sub.payment_term,
         sub.period_id,
         sub.uom_name,
         sub.currency_id,
         sub.journal_id,
         sub.fiscal_position,
         sub.user_id,
         sub.company_id,
         sub.nbr,
         sub.type,
         sub.state,
         sub.categ_id,
         sub.date_due,
         sub.account_id,
         sub.account_line_id,
         sub.partner_bank_id,
         sub.product_qty,
         sub.price_total / cr.rate AS price_total,
         sub.price_average / cr.rate AS price_average,
         cr.rate AS currency_rate,
         sub.residual / cr.rate AS residual,
         sub.commercial_partner_id,
         sub.section_id
  FROM (
         SELECT min(ail.id) AS id,
                ai.date_invoice AS date,
                ail.product_id,
                ai.partner_id,
                ai.payment_term,
                ai.period_id,
                u2.name AS uom_name,
                ai.currency_id,
                ai.journal_id,
                ai.fiscal_position,
                ai.user_id,
                ai.company_id,
                count(ail.*) AS nbr,
                ai.type,
                ai.state,
                pt.categ_id,
                ai.date_due,
                ai.account_id,
                ail.account_id AS account_line_id,
                ai.partner_bank_id,
                sum(CASE
                      WHEN ai.type::text = ANY (ARRAY [ 'out_refund' ::character
                       varying::text, 'in_invoice' ::character varying::text ])
                        THEN (- ail.quantity) / u.factor * u2.factor
                      ELSE ail.quantity / u.factor * u2.factor
                    END) AS product_qty,
                sum(CASE
                      WHEN ai.type::text = ANY (ARRAY [ 'out_refund' ::character
                       varying::text, 'in_invoice' ::character varying::text ])
                        THEN - ail.price_subtotal
                      ELSE ail.price_subtotal
                    END) AS price_total,
                CASE
                  WHEN ai.type::text = ANY (ARRAY [ 'out_refund' ::character
                   varying::text, 'in_invoice' ::character varying::text ]) THEN
                    sum(- ail.price_subtotal)
                  ELSE sum(ail.price_subtotal)
                END / CASE
                        WHEN sum(ail.quantity / u.factor * u2.factor) <>
                         0::numeric THEN CASE
                                           WHEN ai.type::text = ANY (ARRAY [
                                            'out_refund' ::character
                                             varying::text, 'in_invoice'
                                              ::character varying::text ]) THEN
                                               sum((- ail.quantity) / u.factor *
                                                u2.factor)
                                           ELSE sum(ail.quantity / u.factor *
                                            u2.factor)
                                         END
                        ELSE 1::numeric
                      END AS price_average,
                CASE
                  WHEN ai.type::text = ANY (ARRAY [ 'out_refund' ::character
                   varying::text, 'in_invoice' ::character varying::text ]) THEN
                    - ai.residual
                  ELSE ai.residual
                END /((
                        SELECT count(*) AS count
                        FROM account_invoice_line l
                        WHERE l.invoice_id = ai.id
                )) ::numeric * count(*) ::numeric AS residual,
                ai.commercial_partner_id,
                partner.country_id,
                ai.section_id
         FROM account_invoice_line ail
              JOIN account_invoice ai ON ai.id = ail.invoice_id
              JOIN res_partner partner ON ai.commercial_partner_id = partner.id
              LEFT JOIN product_product pr ON pr.id = ail.product_id
              LEFT JOIN product_template pt ON pt.id = pr.product_tmpl_id
              LEFT JOIN product_uom u ON u.id = ail.uos_id
              LEFT JOIN product_uom u2 ON u2.id = pt.uom_id
         GROUP BY ail.product_id,
                  ai.date_invoice,
                  ai.id,
                  ai.partner_id,
                  ai.payment_term,
                  ai.period_id,
                  u2.name,
                  u2.id,
                  ai.currency_id,
                  ai.journal_id,
                  ai.fiscal_position,
                  ai.user_id,
                  ai.company_id,
                  ai.type,
                  ai.state,
                  pt.categ_id,
                  ai.date_due,
                  ai.account_id,
                  ail.account_id,
                  ai.partner_bank_id,
                  ai.residual,
                  ai.amount_total,
                  ai.commercial_partner_id,
                  partner.country_id,
                  ai.section_id
       ) sub
       JOIN res_currency_rate cr ON cr.currency_id = sub.currency_id
  WHERE (cr.id IN (
                    SELECT cr2.id
                    FROM res_currency_rate cr2
                    WHERE cr2.currency_id = sub.currency_id AND
                          (sub.date IS NOT NULL AND
                          cr2.name <= sub.date OR
                          sub.date IS NULL AND
                          cr2.name <= now())
                    ORDER BY cr2.name DESC
                    LIMIT 1
        ));