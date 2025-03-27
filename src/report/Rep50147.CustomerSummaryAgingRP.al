report 50147 "Customeaging_RP"
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
            column(PeriodStartDate_2_; Format(StartDate[2]))
            {
            }
            column(PeriodStartDate_3_; Format(StartDate[3]))
            {
            }
            column(PeriodStartDate_4_; Format(StartDate[4]))
            {
            }
            column(PeriodStartDate_3_1; Format(StartDate[3] - 1))
            {
            }
            column(PeriodStartDate_4_1; Format(StartDate[4] - 1))
            {
            }
            column(PeriodStartDate_5_1; Format(StartDate[5] - 1))
            {
            }

            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(Currency2_Code; TempCurrency.Code)
                {
                }
                column(LineTotalCustBalance; LineTotalCustBalance)
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_1; CustBalanceDue[1])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_2; CustBalanceDue[2])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_3; CustBalanceDue[3])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_4; CustBalanceDue[4])
                {
                    AutoFormatExpression = TempCurrency.Code;
                    AutoFormatType = 1;
                }
                column(CustBalanceDue_5; CustBalanceDue[5])
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
                        DtldCustLedgEntry12.SetRange("Initial Entry Due Date", StartDate[i], StartDate[i + 1] - 1);
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
                detailcustentry: Record "Detailed Cust. Ledg. Entry";
                FilteredCustomer: Record Customer;
            begin
                FilteredCustomer.CopyFilters(Customer);
                FilteredCustomer.SetFilter("Date Filter", '..%1', StartDate[2]);
                LineTotalCustBalance := 0;
                CopyFilter("Currency Filter", detailcustentry."Currency Code");

                for i := 1 to 5 do begin
                    detailcustentry.SetCurrentKey("Customer No.", "Initial Entry Due Date");
                    detailcustentry.SetRange("Customer No.", "No.");
                    detailcustentry.SetRange("Initial Entry Due Date", StartDate[i], StartDate[i + 1] - 1);
                    detailcustentry.CalcSums("Amount (LCY)");
                    CustBalanceDue[i] := detailcustentry."Amount (LCY)";
                    CustBalanceDueLCY[i] := detailcustentry."Amount (LCY)";
                    if PrintAmountsInLCY then
                        InCustBalanceDueLCY[i] += detailcustentry."Amount (LCY)"
                    else
                        InCustBalanceDueLCY2[i] += detailcustentry."Amount (LCY)";
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
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Option';
                    field(StartingDate; StartDate[2])
                    {
                        ApplicationArea = all;
                        Caption = 'Starting Date';
                    }
                    field(PeriodLength; PeriodLengthReq)
                    {
                        ApplicationArea = all;
                        Caption = 'length of period';

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

    labels
    {
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
        Currency: Record Currency;
        TempCurrency: Record Currency temporary;
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

