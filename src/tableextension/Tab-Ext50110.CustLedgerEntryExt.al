tableextension 50110 CustLedgerEntryExt extends "Cust. Ledger Entry"
{
    fields
    {
        field(50100; "Remaining Amount FlowField"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)"
                              where("Cust. Ledger Entry No." = field("Entry No.")));

        }
    }
}
