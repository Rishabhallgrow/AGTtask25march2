report 50123 "Customeaging_RP2"
{
    DefaultLayout = RDLC;
    RDLCLayout = './3CustomerSummaryAging1.rdl';
    ApplicationArea = all;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Filter";

            column(Customer_Name; Name) { }
            column(Customer_No_; "No.") { }
            column(PeriodStartDate_2_; Format(StartDate[2])) { }
            column(PeriodStartDate_3_; Format(StartDate[3])) { }
            column(PeriodStartDate_4_; Format(StartDate[4])) { }
            column(PeriodStartDate_3_1; Format(StartDate[3] - 1)) { }
            column(PeriodStartDate_4_1; Format(StartDate[4] - 1)) { }
            column(PeriodStartDate_5_1; Format(StartDate[5] - 1)) { }
            column(Currency2_Code; DtldCustLedgEntry."Currency Code") { }
            column(LineTotalCustBalance; LineTotalCustBalance)
            {
                AutoFormatExpression = DtldCustLedgEntry."Currency Code";
                AutoFormatType = 1;
            }
            column(CustBalanceDue_1; CustBalanceDue[1])
            {
                AutoFormatExpression = DtldCustLedgEntry."Currency Code";
                AutoFormatType = 1;
            }
            column(CustBalanceDue_2; CustBalanceDue[2])
            {
                AutoFormatExpression = DtldCustLedgEntry."Currency Code";
                AutoFormatType = 1;
            }
            column(CustBalanceDue_3; CustBalanceDue[3])
            {
                AutoFormatExpression = DtldCustLedgEntry."Currency Code";
                AutoFormatType = 1;
            }
            column(CustBalanceDue_4; CustBalanceDue[4])
            {
                AutoFormatExpression = DtldCustLedgEntry."Currency Code";
                AutoFormatType = 1;
            }
            column(CustBalanceDue_5; CustBalanceDue[5])
            {
                AutoFormatExpression = DtldCustLedgEntry."Currency Code";
                AutoFormatType = 1;
            }

            trigger OnAfterGetRecord()
            var
                DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                HasTransactions: Boolean;
            begin
                // 🔹 Reset Values
                Clear(CustBalanceDue);
                Clear(CustBalanceDueLCY);
                LineTotalCustBalance := 0;
                HasTransactions := false;

                // 🔹 Get transactions for this customer
                for i := 1 to 5 do begin
                    DtldCustLedgEntry.Reset();
                    DtldCustLedgEntry.SetRange("Customer No.", Customer."No.");
                    DtldCustLedgEntry.SetRange("Initial Entry Due Date", StartDate[i], StartDate[i + 1] - 1);

                    // 🔹 Apply currency filter properly
                    if Customer."Currency Filter" <> '' then
                        DtldCustLedgEntry.SetRange("Currency Code", Customer."Currency Filter");

                    DtldCustLedgEntry.CalcSums(Amount);

                    CustBalanceDue[i] := DtldCustLedgEntry.Amount;
                    LineTotalCustBalance += CustBalanceDue[i];

                    // 🔹 Check if there are transactions
                    if CustBalanceDue[i] <> 0 then
                        HasTransactions := true;
                end;

                // 🔹 Skip customers without transactions
                if not HasTransactions then
                    CurrReport.SKIP();
            end;

            trigger OnPreDataItem()
            var
                DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                HasData: Boolean;
            begin
                Clear(CustBalanceDue);
                Clear(CustBalanceDueLCY);
                Clear(TotalCustBalanceLCY);

                HasData := false;

                // 🔹 Check if ANY transactions exist in the selected period
                DtldCustLedgEntry.Reset();
                DtldCustLedgEntry.SetRange("Initial Entry Due Date", StartDate[2], StartDate[6]);

                if DtldCustLedgEntry.FindFirst() then
                    HasData := true;

                if not HasData then
                    Error('No customer transactions found in the selected period. Adjust your filters and try again.');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartDate[2])
                    {
                        ApplicationArea = all;
                        Caption = 'Starting Date';
                    }
                    field(PeriodLength; PeriodLengthReq)
                    {
                        ApplicationArea = all;
                        Caption = 'Length of Period';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if StartDate[2] = 0D then
                StartDate[2] := WorkDate();
            if Format(PeriodLengthReq) = '' then
                Evaluate(PeriodLengthReq, '<1M>');
        end;
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        for i := 3 to 5 do
            StartDate[i] := CalcDate(PeriodLengthReq, StartDate[i - 1]);
        StartDate[6] := DMY2Date(31, 12, 9999);
    end;

    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PeriodLengthReq: DateFormula;
        CustFilter: Text;
        PrintAmountsInLCY: Boolean;
        StartDate: array[6] of Date;
        CustBalanceDue: array[5] of Decimal;
        CustBalanceDueLCY: array[5] of Decimal;
        LineTotalCustBalance: Decimal;
        TotalCustBalanceLCY: Decimal;
        i: Integer;
        InCustBalanceDueLCY: array[5] of Decimal;
        InCustBalanceDueLCY2: array[5] of Decimal;
}