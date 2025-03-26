report 50147 "Customer - Summary Aging_RP"
{
    DefaultLayout = RDLC;
    RDLCLayout = './1CustomerSummaryAging1.rdl';
    ApplicationArea = all;
    UsageCategory = ReportsAndAnalysis;
    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Filter";

            column(Customer_Name; Name)
            {
            }
            column(Customer_No_; "No.")
            {
            }

            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(Currency2_Code; TempCurrency.Code)
                {
                }
                column(LineTotalCustBalance_Control67; LineTotalCustBalance)
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_1_Control72; CustBalanceDue[1])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_2_Control71; CustBalanceDue[2])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_3_Control70; CustBalanceDue[3])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_4_Control69; CustBalanceDue[4])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_5_Control68; CustBalanceDue[5])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                trigger OnAfterGetRecord()
                var
                    DtldCustLedgEntry12: Record "Detailed Cust. Ledg. Entry";
                begin
                    if Number = 1 then
                        TempCurrency.Find('-')
                    else
                        if TempCurrency.Next() = 0 then
                            CurrReport.Break();
                    TempCurrency.CalcFields("Cust. Ledg. Entries in Filter");
                    if not TempCurrency."Cust. Ledg. Entries in Filter" then
                        CurrReport.Skip();
                    LineTotalCustBalance := 0;

                    for i := 1 to 5 do begin
                        DtldCustLedgEntry12.SetCurrentKey("Customer No.", "Initial Entry Due Date");
                        DtldCustLedgEntry12.SetRange("Customer No.", Customer."No.");
                        DtldCustLedgEntry12.SetRange("Initial Entry Due Date", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                        DtldCustLedgEntry12.SetRange("Currency Code", TempCurrency.Code);
                        DtldCustLedgEntry12.CalcSums(Amount);
                        CustBalanceDue[i] := DtldCustLedgEntry12.Amount;
                        InCustBalanceDueLCY[i] := InCustBalanceDueLCY2[i];
                        LineTotalCustBalance := LineTotalCustBalance + CustBalanceDue[i];
                    end;
                end;

            }

            trigger OnAfterGetRecord()
            var
                DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                FilteredCustomer: Record Customer;
            begin
                FilteredCustomer.CopyFilters(Customer);
                FilteredCustomer.SetFilter("Date Filter", '..%1', PeriodStartDate[2]);
                LineTotalCustBalance := 0;
                CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");

                for i := 1 to 5 do begin
                    DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Due Date");
                    DtldCustLedgEntry.SetRange("Customer No.", "No.");
                    DtldCustLedgEntry.SetRange("Initial Entry Due Date", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    CustBalanceDue[i] := DtldCustLedgEntry."Amount (LCY)";
                    CustBalanceDueLCY[i] := DtldCustLedgEntry."Amount (LCY)";
                    if PrintAmountsInLCY then
                        InCustBalanceDueLCY[i] += DtldCustLedgEntry."Amount (LCY)"
                    else
                        InCustBalanceDueLCY2[i] += DtldCustLedgEntry."Amount (LCY)";
                    LineTotalCustBalance := LineTotalCustBalance + CustBalanceDueLCY[i];
                    TotalCustBalanceLCY := TotalCustBalanceLCY + CustBalanceDueLCY[i];
                end;

            end;

            trigger OnPreDataItem()
            begin
                Clear(CustBalanceDue);
                Clear(CustBalanceDueLCY);
                Clear(TotalCustBalanceLCY);
                TempCurrency.Code := '';
                TempCurrency.Insert();
                if Currency.Find('-') then
                    repeat
                        TempCurrency := Currency;
                        TempCurrency.Insert();
                    until Currency.Next() = 0;
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
                    field(StartingDate; PeriodStartDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[2] = 0D then
                PeriodStartDate[2] := WorkDate();
            if Format(PeriodLengthReq) = '' then
                Evaluate(PeriodLengthReq, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        for i := 3 to 5 do
            PeriodStartDate[i] := CalcDate(PeriodLengthReq, PeriodStartDate[i - 1]);
        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
    end;

    var
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
        PeriodLengthReq: DateFormula;
        CustFilter: Text;
        PrintAmountsInLCY: Boolean;
        PeriodStartDate: array[6] of Date;
        CustBalanceDue: array[5] of Decimal;
        CustBalanceDueLCY: array[5] of Decimal;
        LineTotalCustBalance: Decimal;
        TotalCustBalanceLCY: Decimal;
        i: Integer;
        InCustBalanceDueLCY: array[5] of Decimal;
        InCustBalanceDueLCY2: array[5] of Decimal;

}

