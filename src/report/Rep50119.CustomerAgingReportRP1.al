report 50119 "Customer Aging Report_RP1"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CustomerAgingReport1.rdl';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";

            column(Customer_No_; "No.") { }
            column(Customer_Name; Name) { }
            column(Before; CustBalanceBefore) { AutoFormatType = 1; }
            column(Period1; CustBalancePeriod[1]) { }
            column(Period2; CustBalancePeriod[2]) { }
            column(Period3; CustBalancePeriod[3]) { }
            column(After; CustBalanceAfter) { }
            column(TotalBalance; TotalBalance) { }

            trigger OnAfterGetRecord()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
            begin
                Clear(CustBalanceBefore);
                Clear(CustBalanceAfter);
                Clear(CustBalancePeriod);
                Clear(TotalBalance);

                // 🔹 Get balance before the first period
                CustLedgEntry.Reset();
                // CustLedgEntry.SetRange("Customer No.", "No.");
                CustLedgEntry.SetFilter("Due Date", '..%1', PeriodStartDate[1] - 1);
                CustLedgEntry.SetAutoCalcFields("Remaining Amount");
                CustBalanceBefore := 0;
                if CustLedgEntry.FindSet() then
                    repeat
                        CustBalanceBefore += CustLedgEntry."Remaining Amount";
                    until CustLedgEntry.Next() = 0;

                // 🔹 Get balances for each period (1 to 3)
                for i := 1 to 3 do begin
                    CustLedgEntry.Reset();
                    // CustLedgEntry.SetRange("Customer No.", "No.");
                    CustLedgEntry.SetRange("Due Date", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    CustLedgEntry.SetAutoCalcFields(CustLedgEntry."Remaining Amount");
                    CustBalancePeriod[i] := 0;
                    if CustLedgEntry.FindSet() then
                        repeat
                            CustBalancePeriod[i] += CustLedgEntry."Remaining Amount";
                        until CustLedgEntry.Next() = 0;
                end;

                // 🔹 Get balance after the last period
                CustLedgEntry.Reset();
                // CustLedgEntry.SetRange("Customer No.", "No.");
                CustLedgEntry.SetFilter("Due Date", '%1..', PeriodStartDate[4]);
                CustLedgEntry.SetAutoCalcFields(CustLedgEntry."Remaining Amount");
                CustBalanceAfter := 0;
                if CustLedgEntry.FindSet() then
                    repeat
                        CustBalanceAfter += CustLedgEntry."Remaining Amount";
                    until CustLedgEntry.Next() = 0;

                // 🔹 Calculate total balance
                TotalBalance := CustBalanceBefore + CustBalancePeriod[1] + CustBalancePeriod[2] + CustBalancePeriod[3] + CustBalanceAfter;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date of the aging period.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if EndDate = 0D then
                EndDate := WorkDate();
        end;
    }

    trigger OnPreReport()
    begin
        // 🔹 Define periods dynamically based on user-selected EndDate
        PeriodStartDate[1] := CalcDate('<-3M>', EndDate); // 3 months before
        PeriodStartDate[2] := CalcDate('<-2M>', EndDate); // 2 months before
        PeriodStartDate[3] := CalcDate('<-1M>', EndDate); // 1 month before
        PeriodStartDate[4] := EndDate;                    // End Date
    end;

    var
        EndDate: Date;
        PeriodStartDate: array[4] of Date;
        CustBalanceBefore: Decimal;
        CustBalanceAfter: Decimal;
        CustBalancePeriod: array[3] of Decimal;
        TotalBalance: Decimal;
        i: Integer;
}
