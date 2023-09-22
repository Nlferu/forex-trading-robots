
#property indicator_separate_window
#property indicator_plots 0

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {

   IndicatorSetDouble(INDICATOR_MAXIMUM,80);
   string short_name=StringFormat("Custom Interface",0);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);


  }
//+------------------------------------------------------------------+
//| Stochastic Oscillator                                            |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   long width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 1);
   long height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 1);

   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

   //+------------------------------------------------------------------+
   //| Account Info Tab                                                 |
   //+------------------------------------------------------------------+
   
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);  
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);   
   double Margin = AccountInfoDouble(ACCOUNT_MARGIN);  
   double FMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   //-------------------------------------------------------------------
   
   // Week Range
   
   MqlRates PriceInfoWeek[];
   ArraySetAsSeries (PriceInfoWeek, true);  
   int DataWeek = CopyRates (_Symbol, PERIOD_W1, 0, 0, PriceInfoWeek);
   ArrayResize(PriceInfoWeek, 33);
   
   double WeekMin = PriceInfoWeek[0].low;   
   double WeekMax = PriceInfoWeek[0].high;
   int WeekRange = 0;

   if(_Digits == 3)
   WeekRange = (int)((WeekMax - WeekMin)*1000);
   
   if(_Digits == 5)
   WeekRange = (int)((WeekMax - WeekMin)*100000);

   //-------------------------------------------------------------------
   
   double WeekPivot = PriceInfoWeek[0].open;
   double DW = 0;
   
   if(Bid >= WeekPivot && WeekPivot != 0)
   DW = (Bid-WeekPivot)/WeekPivot*100;
   
   if(Bid < WeekPivot && WeekPivot != 0)
   DW = (WeekPivot - Bid)/WeekPivot*100;
   
   double WeekChange = NormalizeDouble(DW, 2);


   //-------------------------------------------------------------------   

   // Coordinates
   long widBal = 15;
   if(width != 0)
   widBal = width/(width/15);
   
   long heiBal = 20;
   if(height != 0)
   heiBal = height/(height/20);
   //+------------------------------------------------------------------+
   //|                              Interface                           |
   //+------------------------------------------------------------------+
   //| First Column                                                     |
   //+------------------------------------------------------------------+

   ObjectCreate(0, "Balance",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Balance",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Balance",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Balance",OBJPROP_COLOR, clrGold); 
   ObjectSetString(0, "Balance",OBJPROP_TEXT, "Balance: "+(string) +NormalizeDouble(Balance,2));
   ObjectSetInteger(0, "Balance", OBJPROP_XDISTANCE, widBal);
   ObjectSetInteger(0, "Balance", OBJPROP_YDISTANCE, heiBal);

   ObjectCreate(0, "Equity",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Equity",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Equity",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Equity",OBJPROP_COLOR, clrSandyBrown); 
   ObjectSetString(0, "Equity",OBJPROP_TEXT, "Equity: "+(string) +NormalizeDouble(Equity,2));
   ObjectSetInteger(0, "Equity", OBJPROP_XDISTANCE, 150);
   ObjectSetInteger(0, "Equity", OBJPROP_YDISTANCE, 20); 
   
   ObjectCreate(0, "Margin",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Margin",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Margin",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Margin",OBJPROP_COLOR, clrDarkGoldenrod); 
   ObjectSetString(0, "Margin",OBJPROP_TEXT, "Margin: "+(string) +NormalizeDouble(Margin,2));
   ObjectSetInteger(0, "Margin", OBJPROP_XDISTANCE, 15);
   ObjectSetInteger(0, "Margin", OBJPROP_YDISTANCE, 30);
   
   ObjectCreate(0, "Free Margin",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Free Margin",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Free Margin",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Free Margin",OBJPROP_COLOR, clrMediumSeaGreen); 
   ObjectSetString(0, "Free Margin",OBJPROP_TEXT, "Free Margin: "+(string) +NormalizeDouble(FMargin,2));
   ObjectSetInteger(0, "Free Margin", OBJPROP_XDISTANCE, 150);
   ObjectSetInteger(0, "Free Margin", OBJPROP_YDISTANCE, 30);

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   if(Bid >= WeekPivot)
   {    
   ObjectCreate(0, "WeekRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WeekRange",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "WeekRange",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "WeekRange",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "WeekRange",OBJPROP_TEXT, "This Week Range: "+(string) +WeekRange +" pips" + " +"+(string) +WeekChange+"%");
   ObjectSetInteger(0, "WeekRange", OBJPROP_XDISTANCE, 600);
   ObjectSetInteger(0, "WeekRange", OBJPROP_YDISTANCE, 85);
   }

   if(Bid < WeekPivot)
   {   
   ObjectCreate(0, "WeekRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WeekRange",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "WeekRange",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "WeekRange",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "WeekRange",OBJPROP_TEXT, "This Week Range: "+(string) +WeekRange +" pips" + " -"+(string) +WeekChange+"%");
   ObjectSetInteger(0, "WeekRange", OBJPROP_XDISTANCE, 600);
   ObjectSetInteger(0, "WeekRange", OBJPROP_YDISTANCE, 85);
   }
      
   ObjectCreate(0, "LowestPrice3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice3",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "LowestPrice3",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "LowestPrice3",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "LowestPrice3",OBJPROP_TEXT, "Lowest Price: "+(string) +WeekMin);
   ObjectSetInteger(0, "LowestPrice3", OBJPROP_XDISTANCE, 600);
   ObjectSetInteger(0, "LowestPrice3", OBJPROP_YDISTANCE, 100);
   
   ObjectCreate(0, "MaxPrice3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MaxPrice3",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "MaxPrice3",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "MaxPrice3",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "MaxPrice3",OBJPROP_TEXT, "Max Price: "+(string) +WeekMax);
   ObjectSetInteger(0, "MaxPrice3", OBJPROP_XDISTANCE, 725);
   ObjectSetInteger(0, "MaxPrice3", OBJPROP_YDISTANCE, 100); 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "Yesterday",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Yesterday",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Yesterday",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Yesterday",OBJPROP_COLOR, clrSilver); 
   ObjectSetString(0, "Yesterday",OBJPROP_TEXT, "Yesterday: ");
   ObjectSetInteger(0, "Yesterday", OBJPROP_XDISTANCE, 1185);
   ObjectSetInteger(0, "Yesterday", OBJPROP_YDISTANCE, 60);

   if(YesterdayProfit() >= 0)
   {
   ObjectCreate(0, "Prof2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof2",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Prof2",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Prof2",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Prof2",OBJPROP_TEXT, "+"+(string) +NormalizeDouble(YesterdayProfit(),2));
   ObjectSetInteger(0, "Prof2", OBJPROP_XDISTANCE, 1335);
   ObjectSetInteger(0, "Prof2", OBJPROP_YDISTANCE, 60);
   }

   if(YesterdayProfit() < 0)
   {
   ObjectCreate(0, "Prof2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof2",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Prof2",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Prof2",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Prof2",OBJPROP_TEXT, (string) +NormalizeDouble(YesterdayProfit(),2));
   ObjectSetInteger(0, "Prof2", OBJPROP_XDISTANCE, 1335);
   ObjectSetInteger(0, "Prof2", OBJPROP_YDISTANCE, 60);
   }
   
   if(YesterdayProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain2",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Gain2",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Gain2",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Gain2",OBJPROP_TEXT, "+"+(string) +NormalizeDouble(YesterdayProfit()/Balance*100,2)+"%");
   ObjectSetInteger(0, "Gain2", OBJPROP_XDISTANCE, 1485);
   ObjectSetInteger(0, "Gain2", OBJPROP_YDISTANCE, 60);
   }

   if(YesterdayProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain2",OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, "Gain2",OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "Gain2",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain2",OBJPROP_TEXT, (string) +NormalizeDouble(YesterdayProfit()/Balance*100,2)+"%");
   ObjectSetInteger(0, "Gain2", OBJPROP_XDISTANCE, 1485);
   ObjectSetInteger(0, "Gain2", OBJPROP_YDISTANCE, 60);
   }

   return(rates_total);
  }
//+------------------------------------------------------------------+

   double YesterdayProfit()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";
      double MyResult = 0;
      ulong DealDirection = 0;         
      
      datetime end = TimeCurrent() - PeriodSeconds(PERIOD_D1);                 
      datetime start = end - PeriodSeconds(PERIOD_D1);     
      
      HistorySelect(start, end);
      for(uint i=0; i < TotalNumberOfDeals - TicketNumber; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               DealDirection = HistoryDealGetInteger(TicketNumber,DEAL_TYPE);
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               
               if (OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
            }
         }
      return MyResult;
   }
     