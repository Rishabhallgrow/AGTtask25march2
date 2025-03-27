report 50110 "Customer Aging Report_RP"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CustomerAgingReport.rdl';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";

            dataitem(CustomerLedgerEntry; "Cust. Ledger Entry")
            {
                DataItemLink = "Customer No." = field("No.");
                DataItemTableView = SORTING("Customer No.", "Due Date")
    WHERE(Open = FILTER(true | false));

                column(Customer_No_; Customer."No.") { }
                column(Customer_Name; Customer.Name) { }
                column(Before; "Original Amount") { }
                column(Amount_0_30; Amount_0_30) { }
                column(Amount_31_60; Amount_31_60) { }
                column(Amount_61_90; Amount_61_90) { }
                column(Amount_90_Plus; Amount_90_Plus) { }
                column(TotalRemaining; TotalRemaining) { }

                trigger OnPreDataItem()
                begin
                    // Apply date filters
                    if (PostingDateFrom <> 0D) and (PostingDateTo <> 0D) then
                        SetRange("Posting Date", PostingDateFrom, PostingDateTo);

                    if (DueDateFrom <> 0D) and (DueDateTo <> 0D) then
                        SetRange("Due Date", DueDateFrom, DueDateTo);
                end;

                trigger OnAfterGetRecord()
                var
                    DaysOverdue: Integer;
                begin
                    DaysOverdue := Today - "Due Date";

                    if DaysOverdue < 0 then
                        "Original Amount" += "Remaining Amount"
                    else if DaysOverdue <= 30 then
                        Amount_0_30 += "Remaining Amount"
                    else if DaysOverdue <= 60 then
                        Amount_31_60 += "Remaining Amount"
                    else if DaysOverdue <= 90 then
                        Amount_61_90 += "Remaining Amount"
                    else
                        Amount_90_Plus += "Remaining Amount";

                    // Calculate total remaining amount
                    TotalRemaining := "Original Amount" + Amount_0_30 + Amount_31_60 + Amount_61_90 + Amount_90_Plus;
                end;
            }
        }
    }


    requestpage
    {
        layout
        {
            area(content)
            {
                group(Filtering)
                {
                    Caption = 'Filters';

                    field(AgingReferenceDate; AgingReferenceDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Reference Date';
                        ToolTip = 'Enter the reference date for calculating overdue amounts. Defaults to WorkDate.';
                    }
                    field(PostingDateFrom; PostingDateFrom)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date From';
                    }
                    field(PostingDateTo; PostingDateTo)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date To';
                    }
                    field(DueDateFrom; DueDateFrom)
                    {
                        ApplicationArea = All;
                        Caption = 'Due Date From';
                    }
                    field(DueDateTo; DueDateTo)
                    {
                        ApplicationArea = All;
                        Caption = 'Due Date To';
                    }
                }
            }
        }
    }

    var
        AgingReferenceDate: Date;
        PostingDateFrom: Date;
        PostingDateTo: Date;
        DueDateFrom: Date;
        DueDateTo: Date;
        // BeforeAmount: Decimal;
        Amount_0_30: Decimal;
        Amount_31_60: Decimal;
        Amount_61_90: Decimal;
        Amount_90_Plus: Decimal;
        TotalRemaining: Decimal;
}
