<h3>Charges</h3>

<form method="post" action="opac-account-pay.pl" class="form-horizontal">
[% IF ( ACCOUNT_LINES ) %]
    <table class="table table-bordered table-striped" id="finestable">
        <thead>
            <tr>
                [% IF ( UBOnlinePayment.Active() ) %]<th style="text-align:center"><input id="check-all-payable" type="checkbox"></input></th>[% END %]
                <th class="title-string">Date</th>
                <th>Type</th>
                <th>Description</th>
                <th>Amount</th>
                <th>Amount outstanding</th>
            </tr>
        </thead>

        <tbody>
            [% FOREACH ACCOUNT_LINE IN ACCOUNT_LINES %]
                [% IF ACCOUNT_LINE.amountoutstanding > 0 || ACCOUNT_LINE.amountoutstanding < 0 %]<tr class="outstanding">[% ELSE %]<tr>[% END%]
                    [% IF ( UBOnlinePayment.Active() ) %]
                        <td style="text-align:center"><input aria-label="[% ACCOUNT_LINE.item.biblio.title| html %] [% ACCOUNT_LINE.item.biblio.subtitle| html %] [% ACCOUNT_LINE.amountoutstanding | $Price %]" class="account-line-checkbox" data-accountLineID="[% ACCOUNT_LINE.accountlines_id | html %]"
                                data-payment-status="[% ACCOUNT_LINE.status | html %]" data-item-itype="[% ACCOUNT_LINE.item.itype %]"
                                data-payment-type="[% ACCOUNT_LINE.debit_type_code | html %]"  data-title="[% ACCOUNT_LINE.item.biblio.title| html %]"
                                data-subtitle="[% ACCOUNT_LINE.item.biblio.subtitle| html %]" data-amount="[% ACCOUNT_LINE.amountoutstanding | $Price %]"
                                data-library-code="[% ACCOUNT_LINE.item.homebranch %]" data-misc="" data-barcode="[% ACCOUNT_LINE.item.barcode %]" type="checkbox">
                        </td>
                    [% END %]
                    <td><span title="[% ACCOUNT_LINE.date | html %]">[% ACCOUNT_LINE.date | $KohaDates %]</span></td>
                    <td>
                        [% PROCESS account_type_description account=ACCOUNT_LINE %]
                    </td>
                    <td>
                        [%- IF ACCOUNT_LINE.payment_type %][% AuthorisedValues.GetByCode('PAYMENT_TYPE', ACCOUNT_LINE.payment_type, 1) | html %][% END %]
                        [%- IF ACCOUNT_LINE.description %][% ACCOUNT_LINE.description | html %][% END %]
                        [% IF ACCOUNT_LINE.itemnumber %]([% ACCOUNT_LINE.item.biblio.title | html %])[% END %]
                    </td>
                    [% IF ( ACCOUNT_LINE.is_credit ) %]<td class="credit">[% ACCOUNT_LINE.amount * -1 | $Price %][% ELSE %]<td class="debit">[% ACCOUNT_LINE.amount | $Price %][% END %]</td>
                    [% IF ( ACCOUNT_LINE.is_credit ) %]<td class="credit">[% ACCOUNT_LINE.amountoutstanding * -1 | $Price %][% ELSE %]<td class="debit">[% ACCOUNT_LINE.amountoutstanding | $Price %][% END %]</td>
                </tr>
            [% END %]
        </tbody>

        <tfoot>
            <tr>
                [%- IF UBOnlinePayment.Active() -%]
                    [%- SET COLSPAN = 4 -%]
                [%- ELSE -%]
                    [%- SET COLSPAN = 4 -%]
                [%- END -%]
                <th class="sum" colspan="[% COLSPAN | html %]">Total due</th>
                <td class="sum">[% total | $Price %]</td>
            </tr>
            [% IF outstanding_credits.total_outstanding < 0 %]
            [% FOREACH outstanding_credit IN outstanding_credits %]
                [% IF outstanding_credit.amountoutstanding < 0 %]<tr class="outstanding">[% ELSE %]<tr>[% END%]
                    <td><span title="[% outstanding_credit.date | html %]">[% outstanding_credit.date | $KohaDates %]</span></td>
                    <td>
                        [% PROCESS account_type_description account=outstanding_credit %]
                    </td>
                    <td>
                        [%- IF outstanding_credit.payment_type %][% AuthorisedValues.GetByCode('PAYMENT_TYPE', outstanding_credit.payment_type, 1) | html %][% END %]
                        [%- IF outstanding_credit.description %][% outstanding_credit.description | html %][% END %]
                        [% IF outstanding_credit.itemnumber %]([% outstanding_credit.item.biblio.title | html %])[% END %]
                    </td>
                    <td class="credit">[% outstanding_credit.amount * -1 | $Price %]</td>
                    <td class="credit">[% outstanding_credit.amountoutstanding * -1 | $Price %]</td>
                </tr>
            [% END %]
            <tr>
                <th class="sum" colspan="[% COLSPAN | html %]">Total due if credit(s) applied:</th>
                <td class="sum">[% total + outstanding_credits.total_outstanding | $Price %]</td>
            </tr>
            [% END %]
        </tfoot>

    </table>


[% ELSE %]
    <h4>You have no fines or charges</h4>
[% END %]
</form>

[%- BLOCK account_type_description -%]
    <span>
    [%- IF account.credit_type_code -%]
        [%- SWITCH account.credit_type_code -%]
            [%- CASE 'PAYMENT'          -%]Payment
            [%- CASE 'WRITEOFF'         -%]Writeoff
            [%- CASE 'FORGIVEN'         -%]Forgiven
            [%- CASE 'CREDIT'           -%]Credit
            [%- CASE 'LOST_FOUND'       -%]Lost item fee refund
            [%- CASE                    -%][% account.credit_type.description | html %]
        [%- END -%]
    [%- ELSIF account.debit_type_code -%]
       [%- SWITCH account.debit_type_code -%]
           [%- CASE 'ACCOUNT'          -%]Account creation fee
           [%- CASE 'ACCOUNT_RENEW'    -%]Account renewal fee
           [%- CASE 'LOST'             -%]Lost item
           [%- CASE 'MANUAL'           -%]Manual fee
           [%- CASE 'NEW_CARD'         -%]New card
           [%- CASE 'OVERDUE'          -%]Fine
           [%- CASE 'PROCESSING'       -%]Lost item processing fee
           [%- CASE 'RENT'             -%]Rental fee
           [%- CASE 'RENT_DAILY'       -%]Daily rental fee
           [%- CASE 'RENT_RENEW'       -%]Renewal of rental item
           [%- CASE 'RENT_DAILY_RENEW' -%]Renewal of daily rental item
           [%- CASE 'RESERVE'          -%]Hold fee
           [%- CASE 'RESERVE_EXPIRED'  -%]Hold waiting too long
           [%- CASE                    -%][% account.debit_type.description | html %]
       [%- END -%]
    [%- END -%]
    [%- SWITCH account.status -%]
        [%- CASE 'UNRETURNED' -%]<span> (Accruing)</span>
        [%- CASE 'RETURNED'   -%]<span> (Returned)</span>
        [%- CASE 'REPLACED'   -%]<span> (Replaced)</span>
        [%- CASE 'FORGIVEN'   -%]<span> (Forgiven)</span>
        [%- CASE 'VOID'       -%]<span> (Voided)</span>
        [%- CASE 'LOST'       -%]<span> (Lost)</span>
        [%- CASE              -%]
    [%- END -%]
    </span>
[%- END -%]
