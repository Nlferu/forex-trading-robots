
#property copyright "Copyright 2021, OneTrueTrader"
#property link "https://www.onetruetrader.com"
#property version "2.00"

#property strict
#define LICENSE_TIME (360*86400)           // If time of expiration below not define, tool will expire after X*86400 days where X = days
#define LICENSE_FREE D'2021.05.05 00:00'   // Define time of expiration

#define LICENSE_FULL "OneTrueTrader_InfoPanel"
input string InpLicence = "Enter Licence Key Here";

#include <LicenceCheck.mqh>

#property indicator_separate_window
#property indicator_plots 0

#include <Controls/Panel.mqh>
CPanel panel;

input int FontSize = 10;
input string FontName = "Tahoma";
input bool CompoundResults = true;

double CurMDD = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit()
  {
   
   //IndicatorSetDouble(INDICATOR_MAXIMUM,0); // set 1 to display on chart
   //string short_name = StringFormat("Vampire Trade Info 2.0", 0);
   //IndicatorSetString(INDICATOR_SHORTNAME,short_name);

   if(!LicenceCheck(InpLicence)) 
   return(INIT_FAILED);

   if(LicenceCheck(InpLicence))
   {
      panel.Create(ChartID(),"Indicator_Background",1,0,0,9999,9999);
      panel.ColorBackground(clrBlack);
      ObjectSetInteger(0, "Indicator_Background",OBJPROP_BACK, true);
   }
   
   return(INIT_SUCCEEDED);   
   
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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

   if(!LicenceCheck(InpLicence)) 
   return(INIT_FAILED);

   int SecondaryFontSize = FontSize + 1;
   
   long width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 1);
   long height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 1); 

   if(width == 0 || height == 0)
   {
      width = 350;
      height = 350;
   }

   //+------------------------------------------------------------------+
   //| Account Info Tab                                                 |
   //+------------------------------------------------------------------+
   
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);  
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);   
   double Margin = AccountInfoDouble(ACCOUNT_MARGIN);  
   double FMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   
   //+------------------------------------------------------------------+
   //| Swap Tab                                                         |
   //+------------------------------------------------------------------+

   double LongSwap = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG);
   double ShortSwap = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT);

   //+------------------------------------------------------------------+
   //| Spread and Candle Time Tab                                       |
   //+------------------------------------------------------------------+

   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   
   double Sp = 0;
   
   if(_Digits == 3)
   Sp = (Ask - Bid)*1000;                                                     
   
   if(_Digits == 5)
   Sp = (Ask - Bid)*100000;
   
   double Spread = MathRound(Sp);
   
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(close,true);

   int idxLastBar = rates_total-1;

   int tS,iS,iM,iH;
   string sS,sM,sH;

   tS = (int) time[0] + PeriodSeconds() - (int) TimeCurrent();

   iS = tS%60;

   iM = (tS-iS);
   if(iM != 0)
   iM/=60;
   iM -= (iM-iM%60);

   iH = (tS - iS - iM*60);
   
   if(iH != 0)
   iH /= 60;
   
   if(iH != 0)
   iH /= 60;

   sS = IntegerToString(iS, 2, '0');
   sM = IntegerToString(iM, 2, '0');
   sH = IntegerToString(iH, 2, '0');
  
   //+------------------------------------------------------------------+
   //| Trades Tab                                                       |
   //+------------------------------------------------------------------+ 
   
   int LongTrades = CountBuyPositions();
   int ShortTrades = CountSellPositions();
      
   double LongProfit = LongsProfit();
   double ShortProfit = ShortsProfit();

   int TotalTrades = LongTrades + ShortTrades;
   double TotalProfits = LongProfit + ShortProfit;

   //+------------------------------------------------------------------+
   //| Drawdown Tab                                                     |
   //+------------------------------------------------------------------+ 

   double CurDD = 0;
   
   if(CompoundResults)
   {
      CurDD = Equity - Balance;
   }
   
   if(!CompoundResults)
   {
      CurDD = (Balance + TotalProfits) - Balance;
   }

   //------------------------------------------------------------------
   
   if(CompoundResults)
   {
      if(Equity >= Balance)
      if(CurMDD < CurDD)
      CurMDD = CurDD;
   
      if(Equity < Balance)
      if(CurMDD > CurDD)
      CurMDD = CurDD;
   }
   
   if(!CompoundResults)
   {
      if((Balance + TotalProfits) >= Balance)
      if(CurMDD < CurDD)
      CurMDD = CurDD;
   
      if((Balance + TotalProfits) < Balance)
      if(CurMDD > CurDD)
      CurMDD = CurDD;      
   }

   //+------------------------------------------------------------------+
   //| Range's Tab                                                      |
   //+------------------------------------------------------------------+
   
   MqlRates PriceInfo[];
   ArraySetAsSeries (PriceInfo, true);
   ArrayResize(PriceInfo, 33);
   int Data = CopyRates (_Symbol, PERIOD_D1, 0, 33, PriceInfo);     
   
   // Today's Range
    
   double DailyMin = PriceInfo[0].low;
   double DailyMax = PriceInfo[0].high;
   int TodayRange = 0;

   if(_Digits == 3)
   TodayRange = (int)((DailyMax - DailyMin)*1000);
   
   if(_Digits == 5)
   TodayRange = (int)((DailyMax - DailyMin)*100000);
   
   //-------------------------------------------------------------------
   
   double DailyPivot = PriceInfo[0].open;
   double DC = 0;
   
   if(Bid >= DailyPivot && DailyPivot != 0)
   DC = (Bid-DailyPivot)/DailyPivot*100;
   
   if(Bid < DailyPivot && DailyPivot != 0)
   DC = (DailyPivot - Bid)/DailyPivot*100;
   
   double DailyChange = NormalizeDouble(DC, 2);
   
   // Yesterday's Range
   
   double YesterdayMin = PriceInfo[1].low;   
   double YesterdayMax = PriceInfo[1].high;
   int YesterdayRange = 0;

   if(_Digits == 3)
   YesterdayRange = (int)((YesterdayMax - YesterdayMin)*1000);
   
   if(_Digits == 5)
   YesterdayRange = (int)((YesterdayMax - YesterdayMin)*100000);

   //-------------------------------------------------------------------
   
   double YesterdayPivot = PriceInfo[1].open;
   double DY = 0;
   
   if(Bid >= YesterdayPivot && YesterdayPivot != 0)
   DY = (Bid-YesterdayPivot)/YesterdayPivot*100;
   
   if(Bid < YesterdayPivot && YesterdayPivot != 0)
   DY = (YesterdayPivot - Bid)/YesterdayPivot*100;
   
   double YesterdayChange = NormalizeDouble(DY, 2);
   
   // Week Range
   
   MqlRates PriceInfoWeek[];
   ArraySetAsSeries (PriceInfoWeek, true);
   ArrayResize(PriceInfoWeek, 33);
   int DataWeek = CopyRates (_Symbol, PERIOD_W1, 0, 33, PriceInfoWeek); 
   
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
   
   // Last Week Range

   MqlRates PriceInfoLastWeek[];
   ArraySetAsSeries (PriceInfoLastWeek, true);
   ArrayResize(PriceInfoLastWeek, 33);   
   int DataLastWeek = CopyRates (_Symbol, PERIOD_W1, 0, 33, PriceInfoLastWeek);
   
   double LastWeekMin = PriceInfoLastWeek[1].low;   
   double LastWeekMax = PriceInfoLastWeek[1].high;
   int LastWeekRange = 0;

   if(_Digits == 3)
   LastWeekRange = (int)((LastWeekMax - LastWeekMin)*1000);
   
   if(_Digits == 5)
   LastWeekRange = (int)((LastWeekMax - LastWeekMin)*100000);

   //-------------------------------------------------------------------
   
   double LastWeekPivot = PriceInfoLastWeek[1].open;
   double DLW = 0;
   
   if(Bid >= LastWeekPivot && LastWeekPivot != 0)
   DLW = (Bid-LastWeekPivot)/LastWeekPivot*100;
   
   if(Bid < LastWeekPivot && LastWeekPivot != 0)
   DLW = (LastWeekPivot - Bid)/LastWeekPivot*100;
   
   double LastWeekChange = NormalizeDouble(DLW, 2);
   
   // Month Range

   MqlRates PriceInfoMonth[];
   ArraySetAsSeries (PriceInfoMonth, true);
   ArrayResize(PriceInfoMonth, 33);
   int DataMonth = CopyRates (_Symbol, PERIOD_MN1, 0, 33, PriceInfoMonth);   
   
   double MonthMin = PriceInfoMonth[0].low;   
   double MonthMax = PriceInfoMonth[0].high;
   int MonthRange = 0;

   if(_Digits == 3)
   MonthRange = (int)((MonthMax - MonthMin)*1000);
   
   if(_Digits == 5)
   MonthRange = (int)((MonthMax - MonthMin)*100000);

   //-------------------------------------------------------------------
   
   double MonthPivot = PriceInfoMonth[0].open;
   double DM = 0;
   
   if(Bid >= MonthPivot && MonthPivot != 0)
   DM = (Bid-MonthPivot)/MonthPivot*100;
   
   if(Bid < MonthPivot && MonthPivot != 0)
   DM = (MonthPivot - Bid)/MonthPivot*100;
   
   double MonthChange = NormalizeDouble(DM, 2);

   // LastMonth Range

   MqlRates PriceInfoLastMonth[];
   ArraySetAsSeries (PriceInfoLastMonth, true);
   ArrayResize(PriceInfoLastMonth, 33);
   int DataLastMonth = CopyRates (_Symbol, PERIOD_MN1, 0, 33, PriceInfoLastMonth);  
   
   double LastMonthMin = PriceInfoLastMonth[1].low;   
   double LastMonthMax = PriceInfoLastMonth[1].high;
   int LastMonthRange = 0;

   if(_Digits == 3)
   LastMonthRange = (int)((LastMonthMax - LastMonthMin)*1000);
   
   if(_Digits == 5)
   LastMonthRange = (int)((LastMonthMax - LastMonthMin)*100000);

   //-------------------------------------------------------------------
   
   double LastMonthPivot = PriceInfoLastMonth[1].open;
   double DLM = 0;
   
   if(Bid >= LastMonthPivot && LastMonthPivot != 0)
   DLM = (Bid-LastMonthPivot)/LastMonthPivot*100;
   
   if(Bid < LastMonthPivot && LastMonthPivot != 0)
   DLM = (LastMonthPivot - Bid)/LastMonthPivot*100;
   
   double LastMonthChange = NormalizeDouble(DLM, 2); 
                                            
   //+------------------------------------------------------------------+
   //|                              Interface                           |
   //+------------------------------------------------------------------+
   //| First Column                                                     |
   //+------------------------------------------------------------------+

   ObjectCreate(0, "Indicator_Name",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Indicator_Name",OBJPROP_FONT, "Calisto MT");
   ObjectSetInteger(0, "Indicator_Name",OBJPROP_FONTSIZE, (FontSize-2));
   ObjectSetInteger(0, "Indicator_Name",OBJPROP_COLOR, clrWhite); 
   ObjectSetString(0, "Indicator_Name",OBJPROP_TEXT, "OneTrueTrader Info 2.0");
   ObjectSetInteger(0, "Indicator_Name", OBJPROP_XDISTANCE, (long)(width/160));
   ObjectSetInteger(0, "Indicator_Name", OBJPROP_YDISTANCE, (long)(height/70));
   
   ObjectCreate(0, "WaterMark",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WaterMark",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "WaterMark",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "WaterMark",OBJPROP_COLOR, clrGray); 
   ObjectSetString(0, "WaterMark",OBJPROP_TEXT, "Created by OneTrueTrader - OneTrueTrader@gmail.com");
   ObjectSetInteger(0, "WaterMark", OBJPROP_XDISTANCE, (long)(width/1.431223629)); // 1.338
   ObjectSetInteger(0, "WaterMark", OBJPROP_YDISTANCE, (long)(height/1.15));

   ObjectCreate(0, "Balance",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Balance",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Balance",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Balance",OBJPROP_COLOR, clrGold); 
   ObjectSetString(0, "Balance",OBJPROP_TEXT, "Balance: "+DoubleToString(NormalizeDouble(Balance,2),2));
   ObjectSetInteger(0, "Balance", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "Balance", OBJPROP_YDISTANCE, (long)(height/12));

   ObjectCreate(0, "Equity",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Equity",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Equity",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Equity",OBJPROP_COLOR, clrSandyBrown); 
   ObjectSetString(0, "Equity",OBJPROP_TEXT, "Equity: "+DoubleToString(NormalizeDouble(Equity,2),2));
   ObjectSetInteger(0, "Equity", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "Equity", OBJPROP_YDISTANCE, (long)(height/12)); 
   
   ObjectCreate(0, "Margin",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Margin",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Margin",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Margin",OBJPROP_COLOR, clrDarkGoldenrod); 
   ObjectSetString(0, "Margin",OBJPROP_TEXT, "Margin: "+DoubleToString(NormalizeDouble(Margin,2),2));
   ObjectSetInteger(0, "Margin", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "Margin", OBJPROP_YDISTANCE, (long)(height/6));
   
   ObjectCreate(0, "Free Margin",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Free Margin",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Free Margin",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Free Margin",OBJPROP_COLOR, clrMediumSeaGreen); 
   ObjectSetString(0, "Free Margin",OBJPROP_TEXT, "Free Margin: "+ DoubleToString(NormalizeDouble(FMargin,2),2));
   ObjectSetInteger(0, "Free Margin", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "Free Margin", OBJPROP_YDISTANCE, (long)(height/6));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   //ObjectCreate(0, "Break1",OBJ_LABEL, 1, 0, 0);
   //ObjectSetString(0, "Break1",OBJPROP_FONT, FontName);
   //ObjectSetInteger(0, "Break1",OBJPROP_FONTSIZE, (FontSize+2));
   //ObjectSetInteger(0, "Break1",OBJPROP_COLOR, clrKhaki); 
   //ObjectSetString(0, "Break1",OBJPROP_TEXT, "---------------------------------------------------------------------------");
   //ObjectSetInteger(0, "Break1", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   //ObjectSetInteger(0, "Break1", OBJPROP_YDISTANCE, (long)(height/4.8));           

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
   ObjectCreate(0, "LongSwap",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LongSwap",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LongSwap",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LongSwap",OBJPROP_COLOR, clrGreenYellow); 
   ObjectSetString(0, "LongSwap",OBJPROP_TEXT, "Long Swap: "+DoubleToString(LongSwap,2));
   ObjectSetInteger(0, "LongSwap", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "LongSwap", OBJPROP_YDISTANCE, (long)(height/3.692307692));  
 
   ObjectCreate(0, "ShortSwap",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "ShortSwap",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "ShortSwap",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "ShortSwap",OBJPROP_COLOR, clrRed); 
   ObjectSetString(0, "ShortSwap",OBJPROP_TEXT, "Short Swap: "+DoubleToString(ShortSwap,2));
   ObjectSetInteger(0, "ShortSwap", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "ShortSwap", OBJPROP_YDISTANCE, (long)(height/3.692307692));  

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
   //ObjectCreate(0, "Break2",OBJ_LABEL, 1, 0, 0);
   //ObjectSetString(0, "Break2",OBJPROP_FONT, FontName);
   //ObjectSetInteger(0, "Break2",OBJPROP_FONTSIZE, (FontSize+1));
   //ObjectSetInteger(0, "Break2",OBJPROP_COLOR, clrKhaki); 
   //ObjectSetString(0, "Break2",OBJPROP_TEXT, "---------------------------------------------------------------------------");
   //ObjectSetInteger(0, "Break2", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   //ObjectSetInteger(0, "Break2", OBJPROP_YDISTANCE, (long)(height/3.2));  

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "Spread",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Spread",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Spread",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Spread",OBJPROP_COLOR, clrAqua); 
   ObjectSetString(0, "Spread",OBJPROP_TEXT, "Spread: "+(string)Spread +" pips");
   ObjectSetInteger(0, "Spread", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "Spread", OBJPROP_YDISTANCE, (long)(height/2.666666667)); 
   
   ObjectCreate(0, "NextCandle",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "NextCandle",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "NextCandle",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "NextCandle",OBJPROP_COLOR, clrChocolate); 
   ObjectSetString(0, "NextCandle",OBJPROP_TEXT, "Next Candle: " +sH +":" +sM+ ":" +sS);
   ObjectSetInteger(0, "NextCandle", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "NextCandle", OBJPROP_YDISTANCE, (long)(height/2.666666667));    

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   //ObjectCreate(0, "Break3",OBJ_LABEL, 1, 0, 0);
   //ObjectSetString(0, "Break3",OBJPROP_FONT, FontName);
   //ObjectSetInteger(0, "Break3",OBJPROP_FONTSIZE, FontSize);
   //ObjectSetInteger(0, "Break3",OBJPROP_COLOR, clrKhaki); 
   //ObjectSetString(0, "Break3",OBJPROP_TEXT, "---------------------------------------------------------------------------");
   //ObjectSetInteger(0, "Break3", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   //ObjectSetInteger(0, "Break3", OBJPROP_YDISTANCE, (long)(height/2.4)); 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   if(CurDD >= 0 && Balance != 0)
   { 
   ObjectCreate(0, "CurrentDD",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "CurrentDD",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "CurrentDD",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "CurrentDD",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "CurrentDD",OBJPROP_TEXT, "Current Drawdown: " +" +"+(string)DoubleToString(NormalizeDouble((CurDD/Balance)*100,2),2)+"%"); //+(string)DoubleToString(NormalizeDouble(CurDD,2),2)
   ObjectSetInteger(0, "CurrentDD", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "CurrentDD", OBJPROP_YDISTANCE, (long)(height/2.086956522)); 
   }

   if(CurDD < 0 && Balance != 0)
   { 
   ObjectCreate(0, "CurrentDD",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "CurrentDD",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "CurrentDD",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "CurrentDD",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "CurrentDD",OBJPROP_TEXT, "Current Drawdown: " +" "+(string)DoubleToString(NormalizeDouble((CurDD/Balance)*100,2),2)+"%"); //+(string)DoubleToString(NormalizeDouble(CurDD,2),2)
   ObjectSetInteger(0, "CurrentDD", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "CurrentDD", OBJPROP_YDISTANCE, (long)(height/2.086956522)); 
   }
   
   if(CurMDD >= 0 && Balance != 0)
   {
   ObjectCreate(0, "DailyMaxDD",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "DailyMaxDD",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "DailyMaxDD",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "DailyMaxDD",OBJPROP_COLOR, clrDarkGreen); 
   ObjectSetString(0, "DailyMaxDD",OBJPROP_TEXT, "Max Drawdown: " +" +"+(string)DoubleToString(NormalizeDouble((CurMDD/Balance)*100,2),2)+"%"); //+(string)DoubleToString(NormalizeDouble(CurMDD,2),2)
   ObjectSetInteger(0, "DailyMaxDD", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "DailyMaxDD", OBJPROP_YDISTANCE, (long)(height/2.086956522));     
   }

   if(CurMDD < 0 && Balance != 0)
   {
   ObjectCreate(0, "DailyMaxDD",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "DailyMaxDD",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "DailyMaxDD",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "DailyMaxDD",OBJPROP_COLOR, clrCrimson); 
   ObjectSetString(0, "DailyMaxDD",OBJPROP_TEXT, "Max Drawdown: " +" "+(string)DoubleToString(NormalizeDouble((CurMDD/Balance)*100,2),2)+"%"); //+(string)DoubleToString(NormalizeDouble(CurMDD,2),2)
   ObjectSetInteger(0, "DailyMaxDD", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "DailyMaxDD", OBJPROP_YDISTANCE, (long)(height/2.086956522));     
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   //ObjectCreate(0, "Break4",OBJ_LABEL, 1, 0, 0);
   //ObjectSetString(0, "Break4",OBJPROP_FONT, FontName);
   //ObjectSetInteger(0, "Break4",OBJPROP_FONTSIZE, FontSize);
   //ObjectSetInteger(0, "Break4",OBJPROP_COLOR, clrKhaki); 
   //ObjectSetString(0, "Break4",OBJPROP_TEXT, "---------------------------------------------------------------------------");
   //ObjectSetInteger(0, "Break4", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   //ObjectSetInteger(0, "Break4", OBJPROP_YDISTANCE, (long)(height/1.92)); 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "LongTrades",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LongTrades",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LongTrades",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LongTrades",OBJPROP_COLOR, clrGreen); 
   ObjectSetString(0, "LongTrades",OBJPROP_TEXT, "Long Trades: "+(string)LongTrades);
   ObjectSetInteger(0, "LongTrades", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "LongTrades", OBJPROP_YDISTANCE, (long)(height/1.714285714)); 
 
   ObjectCreate(0, "ShortTrades",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "ShortTrades",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "ShortTrades",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "ShortTrades",OBJPROP_COLOR, clrRed); 
   ObjectSetString(0, "ShortTrades",OBJPROP_TEXT, "Short Trades: "+(string)ShortTrades);
   ObjectSetInteger(0, "ShortTrades", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "ShortTrades", OBJPROP_YDISTANCE, (long)(height/1.5)); 

   if(LongProfit >= 0)
   {   
   ObjectCreate(0, "LProfit",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LProfit",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LProfit",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LProfit",OBJPROP_COLOR, clrGreenYellow); 
   ObjectSetString(0, "LProfit",OBJPROP_TEXT, "Profit: "+DoubleToString(LongProfit,2));
   ObjectSetInteger(0, "LProfit", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "LProfit", OBJPROP_YDISTANCE, (long)(height/1.714285714));  
   }
   
   if(LongProfit < 0)
   {   
   ObjectCreate(0, "LProfit",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LProfit",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LProfit",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LProfit",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "LProfit",OBJPROP_TEXT, "Profit: "+DoubleToString(LongProfit,2));
   ObjectSetInteger(0, "LProfit", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "LProfit", OBJPROP_YDISTANCE, (long)(height/1.714285714));  
   }   
   
   if(ShortProfit >= 0)
   {
   ObjectCreate(0, "SProfit",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "SProfit",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "SProfit",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "SProfit",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "SProfit",OBJPROP_TEXT, "Profit: "+DoubleToString(ShortProfit,2));
   ObjectSetInteger(0, "SProfit", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "SProfit", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   }

   if(ShortProfit < 0)
   {
   ObjectCreate(0, "SProfit",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "SProfit",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "SProfit",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "SProfit",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "SProfit",OBJPROP_TEXT, "Profit: "+DoubleToString(ShortProfit,2));
   ObjectSetInteger(0, "SProfit", OBJPROP_XDISTANCE, (long)(width/6.784));
   ObjectSetInteger(0, "SProfit", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   //ObjectCreate(0, "Break5",OBJ_LABEL, 1, 0, 0);
   //ObjectSetString(0, "Break5",OBJPROP_FONT, FontName);
   //ObjectSetInteger(0, "Break5",OBJPROP_FONTSIZE, FontSize);
   //ObjectSetInteger(0, "Break5",OBJPROP_COLOR, clrKhaki); 
   //ObjectSetString(0, "Break5",OBJPROP_TEXT, "---------------------------------------------------------------------------");
   //ObjectSetInteger(0, "Break5", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   //ObjectSetInteger(0, "Break5", OBJPROP_YDISTANCE, (long)(height/1.411764706));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "TotalTrades",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TotalTrades",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TotalTrades",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "TotalTrades",OBJPROP_COLOR, clrDarkSlateBlue); 
   ObjectSetString(0, "TotalTrades",OBJPROP_TEXT, "Total Trades: "+ (string)TotalTrades);
   ObjectSetInteger(0, "TotalTrades", OBJPROP_XDISTANCE, (long)(width/113.0666667));
   ObjectSetInteger(0, "TotalTrades", OBJPROP_YDISTANCE, (long)(height/1.263157895));

   if(TotalProfits >= 0)
   { 
   ObjectCreate(0, "TotalProfit",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TotalProfit",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TotalProfit",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "TotalProfit",OBJPROP_COLOR, clrYellowGreen); 
   ObjectSetString(0, "TotalProfit",OBJPROP_TEXT, "Total Profit: "+ DoubleToString(TotalProfits, 2));
   ObjectSetInteger(0, "TotalProfit", OBJPROP_XDISTANCE, (long)(width/6.81124498));
   ObjectSetInteger(0, "TotalProfit", OBJPROP_YDISTANCE, (long)(height/1.263157895));                   
   }
 
   if(TotalProfits < 0)
   { 
   ObjectCreate(0, "TotalProfit",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TotalProfit",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TotalProfit",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "TotalProfit",OBJPROP_COLOR, clrCrimson); 
   ObjectSetString(0, "TotalProfit",OBJPROP_TEXT, "Total Profit: "+ DoubleToString(TotalProfits, 2));
   ObjectSetInteger(0, "TotalProfit", OBJPROP_XDISTANCE, (long)(width/6.81124498));
   ObjectSetInteger(0, "TotalProfit", OBJPROP_YDISTANCE, (long)(height/1.263157895));                     
   }
      
   //+------------------------------------------------------------------+
   //| Second Column                                                    |
   //+------------------------------------------------------------------+

   ObjectCreate(0, "TodayRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TodayRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TodayRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "TodayRange2",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "TodayRange2",OBJPROP_TEXT, "Today's Range: ");
   ObjectSetInteger(0, "TodayRange2", OBJPROP_XDISTANCE, (long)(width/3.392)); 
   ObjectSetInteger(0, "TodayRange2", OBJPROP_YDISTANCE, (long)(height/12));

   ObjectCreate(0, "pips1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "pips1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "pips1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "pips1",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "pips1",OBJPROP_TEXT, "PIPs' ");
   ObjectSetInteger(0, "pips1", OBJPROP_XDISTANCE, (long)(width/2.640866142));
   ObjectSetInteger(0, "pips1", OBJPROP_YDISTANCE, (long)(height/12));

   if(Bid >= DailyPivot)
   { 
   ObjectCreate(0, "TodayRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TodayRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TodayRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "TodayRange",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "TodayRange",OBJPROP_TEXT, (string)TodayRange);
   ObjectSetInteger(0, "TodayRange", OBJPROP_XDISTANCE, (long)(width/2.83)); 
   ObjectSetInteger(0, "TodayRange", OBJPROP_YDISTANCE, (long)(height/12)); 
   }
   
   if(Bid < DailyPivot)
   {   
   ObjectCreate(0, "TodayRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TodayRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TodayRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "TodayRange",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "TodayRange",OBJPROP_TEXT, (string)TodayRange);
   ObjectSetInteger(0, "TodayRange", OBJPROP_XDISTANCE, (long)(width/2.83));
   ObjectSetInteger(0, "TodayRange", OBJPROP_YDISTANCE, (long)(height/12));
   }

   if(Bid >= DailyPivot)
   { 
   ObjectCreate(0, "TodayRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TodayRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TodayRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "TodayRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "TodayRange1",OBJPROP_TEXT, "+"+DoubleToString(DailyChange,2)+"%");
   ObjectSetInteger(0, "TodayRange1", OBJPROP_XDISTANCE, (long)(width/2.4)); 
   ObjectSetInteger(0, "TodayRange1", OBJPROP_YDISTANCE, (long)(height/12)); 
   }
   
   if(Bid < DailyPivot)
   {   
   ObjectCreate(0, "TodayRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "TodayRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "TodayRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "TodayRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "TodayRange1",OBJPROP_TEXT, "-"+DoubleToString(DailyChange,2)+"%");
   ObjectSetInteger(0, "TodayRange1", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "TodayRange1", OBJPROP_YDISTANCE, (long)(height/12));
   } 

   ObjectCreate(0, "LowestPrice1Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice1Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice1Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice1Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice1Plate",OBJPROP_TEXT, "Lowest Price: ");
   ObjectSetInteger(0, "LowestPrice1Plate", OBJPROP_XDISTANCE, (long)(width/3.392));
   ObjectSetInteger(0, "LowestPrice1Plate", OBJPROP_YDISTANCE, (long)(height/6.557142857));

   ObjectCreate(0, "LowestPrice11Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice11Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice11Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice11Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice11Plate",OBJPROP_TEXT, "Max Price: ");
   ObjectSetInteger(0, "LowestPrice11Plate", OBJPROP_XDISTANCE, (long)(width/2.640866142));
   ObjectSetInteger(0, "LowestPrice11Plate", OBJPROP_YDISTANCE, (long)(height/6.557142857));
   
   ObjectCreate(0, "LowestPrice1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice1",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "LowestPrice1",OBJPROP_TEXT, DoubleToString(DailyMin,_Digits));
   ObjectSetInteger(0, "LowestPrice1", OBJPROP_XDISTANCE, (long)(width/2.9));
   ObjectSetInteger(0, "LowestPrice1", OBJPROP_YDISTANCE, (long)(height/6.557142857));
   
   ObjectCreate(0, "MaxPrice1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MaxPrice1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MaxPrice1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MaxPrice1",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "MaxPrice1",OBJPROP_TEXT, DoubleToString(DailyMax,_Digits));
   ObjectSetInteger(0, "MaxPrice1", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "MaxPrice1", OBJPROP_YDISTANCE, (long)(height/6.557142857));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "YesterdayRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "YesterdayRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "YesterdayRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "YesterdayRange",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "YesterdayRange",OBJPROP_TEXT, "Yesterday's Range: ");
   ObjectSetInteger(0, "YesterdayRange", OBJPROP_XDISTANCE, (long)(width/2.12));
   ObjectSetInteger(0, "YesterdayRange", OBJPROP_YDISTANCE, (long)(height/12)); 

   ObjectCreate(0, "pips4",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "pips4",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "pips4",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "pips4",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "pips4",OBJPROP_TEXT, "PIPs' ");
   ObjectSetInteger(0, "pips4", OBJPROP_XDISTANCE, (long)(width/1.75));
   ObjectSetInteger(0, "pips4", OBJPROP_YDISTANCE, (long)(height/12)); 

   if(Bid >= YesterdayPivot)
   {   
   ObjectCreate(0, "YesterdayRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "YesterdayRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "YesterdayRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "YesterdayRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "YesterdayRange1",OBJPROP_TEXT, (string)YesterdayRange);
   ObjectSetInteger(0, "YesterdayRange1", OBJPROP_XDISTANCE, (long)(width/1.83));
   ObjectSetInteger(0, "YesterdayRange1", OBJPROP_YDISTANCE, (long)(height/12));         
   }

   if(Bid < YesterdayPivot)
   {   
   ObjectCreate(0, "YesterdayRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "YesterdayRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "YesterdayRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "YesterdayRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "YesterdayRange1",OBJPROP_TEXT, (string)YesterdayRange);
   ObjectSetInteger(0, "YesterdayRange1", OBJPROP_XDISTANCE, (long)(width/1.83));
   ObjectSetInteger(0, "YesterdayRange1", OBJPROP_YDISTANCE, (long)(height/12));         
   }

   if(Bid >= YesterdayPivot)
   {   
   ObjectCreate(0, "YesterdayRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "YesterdayRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "YesterdayRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "YesterdayRange2",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "YesterdayRange2",OBJPROP_TEXT, "+"+DoubleToString(YesterdayChange,2)+"%");
   ObjectSetInteger(0, "YesterdayRange2", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "YesterdayRange2", OBJPROP_YDISTANCE, (long)(height/12));         
   }

   if(Bid < YesterdayPivot)
   {   
   ObjectCreate(0, "YesterdayRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "YesterdayRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "YesterdayRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "YesterdayRange2",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "YesterdayRange2",OBJPROP_TEXT, "-"+DoubleToString(YesterdayChange,2)+"%");
   ObjectSetInteger(0, "YesterdayRange2", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "YesterdayRange2", OBJPROP_YDISTANCE, (long)(height/12));         
   }

   ObjectCreate(0, "LowestPrice2Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice2Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice2Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice2Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice2Plate",OBJPROP_TEXT, "Lowest Price: ");
   ObjectSetInteger(0, "LowestPrice2Plate", OBJPROP_XDISTANCE, (long)(width/2.12));
   ObjectSetInteger(0, "LowestPrice2Plate", OBJPROP_YDISTANCE, (long)(height/6.557142857));

   ObjectCreate(0, "LowestPrice22Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice22Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice22Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice22Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice22Plate",OBJPROP_TEXT, "Max Price: ");
   ObjectSetInteger(0, "LowestPrice22Plate", OBJPROP_XDISTANCE, (long)(width/1.80));
   ObjectSetInteger(0, "LowestPrice22Plate", OBJPROP_YDISTANCE, (long)(height/6.557142857));
  
   ObjectCreate(0, "LowestPrice2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice2",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "LowestPrice2",OBJPROP_TEXT, DoubleToString(YesterdayMin,_Digits));
   ObjectSetInteger(0, "LowestPrice2", OBJPROP_XDISTANCE, (long)(width/1.92));
   ObjectSetInteger(0, "LowestPrice2", OBJPROP_YDISTANCE, (long)(height/6.557142857));
   
   ObjectCreate(0, "MaxPrice2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MaxPrice2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MaxPrice2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MaxPrice2",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "MaxPrice2",OBJPROP_TEXT, DoubleToString(YesterdayMax,_Digits));
   ObjectSetInteger(0, "MaxPrice2", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "MaxPrice2", OBJPROP_YDISTANCE, (long)(height/6.557142857));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "WeekRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WeekRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "WeekRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "WeekRange2",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "WeekRange2",OBJPROP_TEXT, "Weekly Range: ");
   ObjectSetInteger(0, "WeekRange2", OBJPROP_XDISTANCE, (long)(width/3.392));
   ObjectSetInteger(0, "WeekRange2", OBJPROP_YDISTANCE, (long)(height/2.666666667));

   ObjectCreate(0, "pips2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "pips2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "pips2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "pips2",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "pips2",OBJPROP_TEXT, "PIPs' ");
   ObjectSetInteger(0, "pips2", OBJPROP_XDISTANCE, (long)(width/2.640866142));
   ObjectSetInteger(0, "pips2", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   
   if(Bid >= WeekPivot)
   {    
   ObjectCreate(0, "WeekRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WeekRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "WeekRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "WeekRange",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "WeekRange",OBJPROP_TEXT, (string)WeekRange);
   ObjectSetInteger(0, "WeekRange", OBJPROP_XDISTANCE, (long)(width/2.83));
   ObjectSetInteger(0, "WeekRange", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }

   if(Bid < WeekPivot)
   {   
   ObjectCreate(0, "WeekRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WeekRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "WeekRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "WeekRange",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "WeekRange",OBJPROP_TEXT, (string)WeekRange);
   ObjectSetInteger(0, "WeekRange", OBJPROP_XDISTANCE, (long)(width/2.83));
   ObjectSetInteger(0, "WeekRange", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }

   if(Bid >= WeekPivot)
   {    
   ObjectCreate(0, "WeekRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WeekRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "WeekRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "WeekRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "WeekRange1",OBJPROP_TEXT, "+"+DoubleToString(WeekChange,2)+"%");
   ObjectSetInteger(0, "WeekRange1", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "WeekRange1", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }

   if(Bid < WeekPivot)
   {   
   ObjectCreate(0, "WeekRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "WeekRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "WeekRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "WeekRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "WeekRange1",OBJPROP_TEXT, "-"+DoubleToString(WeekChange,2)+"%");
   ObjectSetInteger(0, "WeekRange1", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "WeekRange1", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }

   ObjectCreate(0, "LowestPrice3Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice3Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice3Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice3Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice3Plate",OBJPROP_TEXT, "Lowest Price: ");
   ObjectSetInteger(0, "LowestPrice3Plate", OBJPROP_XDISTANCE, (long)(width/3.392));
   ObjectSetInteger(0, "LowestPrice3Plate", OBJPROP_YDISTANCE, (long)(height/2.255714286));

   ObjectCreate(0, "LowestPrice33Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice33Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice33Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice33Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice33Plate",OBJPROP_TEXT, "Max Price: ");
   ObjectSetInteger(0, "LowestPrice33Plate", OBJPROP_XDISTANCE, (long)(width/2.640866142));
   ObjectSetInteger(0, "LowestPrice33Plate", OBJPROP_YDISTANCE, (long)(height/2.255714286));
      
   ObjectCreate(0, "LowestPrice3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice3",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice3",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice3",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "LowestPrice3",OBJPROP_TEXT, DoubleToString(WeekMin,_Digits));
   ObjectSetInteger(0, "LowestPrice3", OBJPROP_XDISTANCE, (long)(width/2.9));
   ObjectSetInteger(0, "LowestPrice3", OBJPROP_YDISTANCE, (long)(height/2.255714286));
   
   ObjectCreate(0, "MaxPrice3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MaxPrice3",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MaxPrice3",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MaxPrice3",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "MaxPrice3",OBJPROP_TEXT, DoubleToString(WeekMax,_Digits));
   ObjectSetInteger(0, "MaxPrice3", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "MaxPrice3", OBJPROP_YDISTANCE, (long)(height/2.255714286)); 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "LastWeekRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastWeekRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastWeekRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastWeekRange",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LastWeekRange",OBJPROP_TEXT, "Last Week Range: ");
   ObjectSetInteger(0, "LastWeekRange", OBJPROP_XDISTANCE, (long)(width/2.12));
   ObjectSetInteger(0, "LastWeekRange", OBJPROP_YDISTANCE, (long)(height/2.666666667)); 

   ObjectCreate(0, "pips5",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "pips5",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "pips5",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "pips5",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "pips5",OBJPROP_TEXT, "PIPs' ");
   ObjectSetInteger(0, "pips5", OBJPROP_XDISTANCE, (long)(width/1.75));
   ObjectSetInteger(0, "pips5", OBJPROP_YDISTANCE, (long)(height/2.666666667));

   if(Bid >= LastWeekPivot)
   {   
   ObjectCreate(0, "LastWeekRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastWeekRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastWeekRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastWeekRange1",OBJPROP_COLOR, clrWheat);
   ObjectSetString(0, "LastWeekRange1",OBJPROP_TEXT, (string)LastWeekRange);
   ObjectSetInteger(0, "LastWeekRange1", OBJPROP_XDISTANCE, (long)(width/1.83));
   ObjectSetInteger(0, "LastWeekRange1", OBJPROP_YDISTANCE, (long)(height/2.666666667)); 
   }

   if(Bid < LastWeekPivot)
   {   
   ObjectCreate(0, "LastWeekRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastWeekRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastWeekRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastWeekRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "LastWeekRange1",OBJPROP_TEXT, (string)LastWeekRange);
   ObjectSetInteger(0, "LastWeekRange1", OBJPROP_XDISTANCE, (long)(width/1.83));
   ObjectSetInteger(0, "LastWeekRange1", OBJPROP_YDISTANCE, (long)(height/2.666666667)); 
   }

   if(Bid >= LastWeekPivot)
   {   
   ObjectCreate(0, "LastWeekRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastWeekRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastWeekRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastWeekRange2",OBJPROP_COLOR, clrWheat);
   ObjectSetString(0, "LastWeekRange2",OBJPROP_TEXT, "+"+DoubleToString(LastWeekChange,2)+"%");
   ObjectSetInteger(0, "LastWeekRange2", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "LastWeekRange2", OBJPROP_YDISTANCE, (long)(height/2.666666667)); 
   }

   if(Bid < LastWeekPivot)
   {   
   ObjectCreate(0, "LastWeekRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastWeekRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastWeekRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastWeekRange2",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "LastWeekRange2",OBJPROP_TEXT, "-"+DoubleToString(LastWeekChange,2)+"%");
   ObjectSetInteger(0, "LastWeekRange2", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "LastWeekRange2", OBJPROP_YDISTANCE, (long)(height/2.666666667)); 
   }

   ObjectCreate(0, "LowestPrice4Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice4Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice4Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice4Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice4Plate",OBJPROP_TEXT, "Lowest Price: ");
   ObjectSetInteger(0, "LowestPrice4Plate", OBJPROP_XDISTANCE, (long)(width/2.12));
   ObjectSetInteger(0, "LowestPrice4Plate", OBJPROP_YDISTANCE, (long)(height/2.255714286));

   ObjectCreate(0, "LowestPrice44Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice44Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice44Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice44Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice44Plate",OBJPROP_TEXT, "Max Price: ");
   ObjectSetInteger(0, "LowestPrice44Plate", OBJPROP_XDISTANCE, (long)(width/1.80));
   ObjectSetInteger(0, "LowestPrice44Plate", OBJPROP_YDISTANCE, (long)(height/2.255714286));
   
   ObjectCreate(0, "LowestPrice4",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice4",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice4",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice4",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "LowestPrice4",OBJPROP_TEXT, DoubleToString(LastWeekMin,_Digits));
   ObjectSetInteger(0, "LowestPrice4", OBJPROP_XDISTANCE, (long)(width/1.92));
   ObjectSetInteger(0, "LowestPrice4", OBJPROP_YDISTANCE, (long)(height/2.255714286));
   
   ObjectCreate(0, "MaxPrice4",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MaxPrice4",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MaxPrice4",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MaxPrice4",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "MaxPrice4",OBJPROP_TEXT, DoubleToString(LastWeekMax,_Digits));
   ObjectSetInteger(0, "MaxPrice4", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "MaxPrice4", OBJPROP_YDISTANCE, (long)(height/2.255714286));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "MonthRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MonthRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MonthRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MonthRange2",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "MonthRange2",OBJPROP_TEXT, "Monthly Range: ");
   ObjectSetInteger(0, "MonthRange2", OBJPROP_XDISTANCE, (long)(width/3.392));
   ObjectSetInteger(0, "MonthRange2", OBJPROP_YDISTANCE, (long)(height/1.5));

   ObjectCreate(0, "pips3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "pips3",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "pips3",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "pips3",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "pips3",OBJPROP_TEXT, "PIPs' ");
   ObjectSetInteger(0, "pips3", OBJPROP_XDISTANCE, (long)(width/2.640866142));
   ObjectSetInteger(0, "pips3", OBJPROP_YDISTANCE, (long)(height/1.5));

   if(Bid >= MonthPivot)
   {  
   ObjectCreate(0, "MonthRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MonthRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MonthRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MonthRange",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "MonthRange",OBJPROP_TEXT, (string)MonthRange);
   ObjectSetInteger(0, "MonthRange", OBJPROP_XDISTANCE, (long)(width/2.83));
   ObjectSetInteger(0, "MonthRange", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   }
   
   if(Bid < MonthPivot)
   {  
   ObjectCreate(0, "MonthRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MonthRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MonthRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MonthRange",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "MonthRange",OBJPROP_TEXT, (string)MonthRange);
   ObjectSetInteger(0, "MonthRange", OBJPROP_XDISTANCE, (long)(width/2.83));
   ObjectSetInteger(0, "MonthRange", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   }   

   if(Bid >= MonthPivot)
   {  
   ObjectCreate(0, "MonthRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MonthRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MonthRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MonthRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "MonthRange1",OBJPROP_TEXT, "+"+DoubleToString(MonthChange,2)+"%");
   ObjectSetInteger(0, "MonthRange1", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "MonthRange1", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   }
   
   if(Bid < MonthPivot)
   {  
   ObjectCreate(0, "MonthRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MonthRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MonthRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MonthRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "MonthRange1",OBJPROP_TEXT, "-"+DoubleToString(MonthChange,2)+"%");
   ObjectSetInteger(0, "MonthRange1", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "MonthRange1", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   } 

   ObjectCreate(0, "LowestPrice5Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice5Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice5Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice5Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice5Plate",OBJPROP_TEXT, "Lowest Price: ");
   ObjectSetInteger(0, "LowestPrice5Plate", OBJPROP_XDISTANCE, (long)(width/3.392));
   ObjectSetInteger(0, "LowestPrice5Plate", OBJPROP_YDISTANCE, (long)(height/1.351428571));

   ObjectCreate(0, "LowestPrice55Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice55Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice55Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice55Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice55Plate",OBJPROP_TEXT, "Max Price: ");
   ObjectSetInteger(0, "LowestPrice55Plate", OBJPROP_XDISTANCE, (long)(width/2.640866142));
   ObjectSetInteger(0, "LowestPrice55Plate", OBJPROP_YDISTANCE, (long)(height/1.351428571));
   
   ObjectCreate(0, "LowestPrice5",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice5",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice5",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice5",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "LowestPrice5",OBJPROP_TEXT, DoubleToString(MonthMin,_Digits));
   ObjectSetInteger(0, "LowestPrice5", OBJPROP_XDISTANCE, (long)(width/2.9));
   ObjectSetInteger(0, "LowestPrice5", OBJPROP_YDISTANCE, (long)(height/1.351428571));
   
   ObjectCreate(0, "MaxPrice5",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MaxPrice5",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MaxPrice5",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MaxPrice5",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "MaxPrice5",OBJPROP_TEXT, DoubleToString(MonthMax,_Digits));
   ObjectSetInteger(0, "MaxPrice5", OBJPROP_XDISTANCE, (long)(width/2.4));
   ObjectSetInteger(0, "MaxPrice5", OBJPROP_YDISTANCE, (long)(height/1.351428571));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "LastMonthRange",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastMonthRange",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastMonthRange",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastMonthRange",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LastMonthRange",OBJPROP_TEXT, "Last Month Range: ");
   ObjectSetInteger(0, "LastMonthRange", OBJPROP_XDISTANCE, (long)(width/2.12));
   ObjectSetInteger(0, "LastMonthRange", OBJPROP_YDISTANCE, (long)(height/1.5));

   ObjectCreate(0, "pips6",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "pips6",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "pips6",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "pips6",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "pips6",OBJPROP_TEXT, "PIPs' ");
   ObjectSetInteger(0, "pips6", OBJPROP_XDISTANCE, (long)(width/1.75));
   ObjectSetInteger(0, "pips6", OBJPROP_YDISTANCE, (long)(height/1.5));

   if(Bid >= LastMonthPivot)
   {  
   ObjectCreate(0, "LastMonthRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastMonthRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastMonthRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastMonthRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "LastMonthRange1",OBJPROP_TEXT, (string)LastMonthRange);
   ObjectSetInteger(0, "LastMonthRange1", OBJPROP_XDISTANCE, (long)(width/1.83));
   ObjectSetInteger(0, "LastMonthRange1", OBJPROP_YDISTANCE, (long)(height/1.5));
   }
   
   if(Bid < LastMonthPivot)
   {  
   ObjectCreate(0, "LastMonthRange1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastMonthRange1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastMonthRange1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastMonthRange1",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "LastMonthRange1",OBJPROP_TEXT, (string)LastMonthRange);
   ObjectSetInteger(0, "LastMonthRange1", OBJPROP_XDISTANCE, (long)(width/1.83));
   ObjectSetInteger(0, "LastMonthRange1", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   }   

   if(Bid >= LastMonthPivot)
   {  
   ObjectCreate(0, "LastMonthRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastMonthRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastMonthRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastMonthRange2",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "LastMonthRange2",OBJPROP_TEXT, "+"+DoubleToString(LastMonthChange,2)+"%");
   ObjectSetInteger(0, "LastMonthRange2", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "LastMonthRange2", OBJPROP_YDISTANCE, (long)(height/1.5));
   }
   
   if(Bid < LastMonthPivot)
   {  
   ObjectCreate(0, "LastMonthRange2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastMonthRange2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastMonthRange2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastMonthRange2",OBJPROP_COLOR, clrWheat); 
   ObjectSetString(0, "LastMonthRange2",OBJPROP_TEXT, "-"+DoubleToString(LastMonthChange,2)+"%");
   ObjectSetInteger(0, "LastMonthRange2", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "LastMonthRange2", OBJPROP_YDISTANCE, (long)(height/1.5)); 
   } 

   ObjectCreate(0, "LowestPrice6Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice6Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice6Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice6Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice6Plate",OBJPROP_TEXT, "Lowest Price: ");
   ObjectSetInteger(0, "LowestPrice6Plate", OBJPROP_XDISTANCE, (long)(width/2.12));
   ObjectSetInteger(0, "LowestPrice6Plate", OBJPROP_YDISTANCE, (long)(height/1.351428571));

   ObjectCreate(0, "LowestPrice66Plate",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice66Plate",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice66Plate",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice66Plate",OBJPROP_COLOR, clrTeal); 
   ObjectSetString(0, "LowestPrice66Plate",OBJPROP_TEXT, "Max Price: ");
   ObjectSetInteger(0, "LowestPrice66Plate", OBJPROP_XDISTANCE, (long)(width/1.80));
   ObjectSetInteger(0, "LowestPrice66Plate", OBJPROP_YDISTANCE, (long)(height/1.351428571));
   
   ObjectCreate(0, "LowestPrice6",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LowestPrice6",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LowestPrice6",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LowestPrice6",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "LowestPrice6",OBJPROP_TEXT, DoubleToString(LastMonthMin,_Digits));
   ObjectSetInteger(0, "LowestPrice6", OBJPROP_XDISTANCE, (long)(width/1.92));
   ObjectSetInteger(0, "LowestPrice6", OBJPROP_YDISTANCE, (long)(height/1.351428571));
   
   ObjectCreate(0, "MaxPrice6",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "MaxPrice6",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "MaxPrice6",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "MaxPrice6",OBJPROP_COLOR, clrDarkKhaki); 
   ObjectSetString(0, "MaxPrice6",OBJPROP_TEXT, DoubleToString(LastMonthMax,_Digits));
   ObjectSetInteger(0, "MaxPrice6", OBJPROP_XDISTANCE, (long)(width/1.67));
   ObjectSetInteger(0, "MaxPrice6", OBJPROP_YDISTANCE, (long)(height/1.351428571));

   //+------------------------------------------------------------------+
   //| Third Column                                                     |
   //+------------------------------------------------------------------+
 
   ObjectCreate(0, "Date",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Date",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Date",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Date",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "Date",OBJPROP_TEXT, "Date");
   ObjectSetInteger(0, "Date", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Date", OBJPROP_YDISTANCE, (long)(height/12));
   
   ObjectCreate(0, "ProfitSum",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "ProfitSum",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "ProfitSum",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "ProfitSum",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "ProfitSum",OBJPROP_TEXT, "Profit");
   ObjectSetInteger(0, "ProfitSum", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "ProfitSum", OBJPROP_YDISTANCE, (long)(height/12));
   
   ObjectCreate(0, "Gain",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "Gain",OBJPROP_TEXT, "Gain");
   ObjectSetInteger(0, "Gain", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain", OBJPROP_YDISTANCE, (long)(height/12));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "Break6",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Break6",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Break6",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Break6",OBJPROP_COLOR, clrKhaki); 
   ObjectSetString(0, "Break6",OBJPROP_TEXT, "=========================================");
   ObjectSetInteger(0, "Break6", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Break6", OBJPROP_YDISTANCE, (long)(height/6.857142857)); 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "Today",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Today",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Today",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Today",OBJPROP_COLOR, clrWhite); 
   ObjectSetString(0, "Today",OBJPROP_TEXT, "Today: ");
   ObjectSetInteger(0, "Today", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Today", OBJPROP_YDISTANCE, (long)(height/4.8));

   if(TodayProfit() >= 0)
   {
   ObjectCreate(0, "Prof1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof1",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Prof1",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(TodayProfit(),2),2));
   ObjectSetInteger(0, "Prof1", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof1", OBJPROP_YDISTANCE, (long)(height/4.8));
   }

   if(TodayProfit() < 0)
   {
   ObjectCreate(0, "Prof1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof1",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Prof1",OBJPROP_TEXT, DoubleToString(NormalizeDouble(TodayProfit(),2),2));
   ObjectSetInteger(0, "Prof1", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof1", OBJPROP_YDISTANCE, (long)(height/4.8));
   }
   
   if(TodayProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain1",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Gain1",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(TodayProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain1", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain1", OBJPROP_YDISTANCE, (long)(height/4.8));   
   }

   if(TodayProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain1",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain1",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain1",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain1",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain1",OBJPROP_TEXT, DoubleToString(NormalizeDouble(TodayProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain1", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain1", OBJPROP_YDISTANCE, (long)(height/4.8));   
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "Yesterday",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Yesterday",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Yesterday",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Yesterday",OBJPROP_COLOR, clrSilver); 
   ObjectSetString(0, "Yesterday",OBJPROP_TEXT, "Yesterday: ");
   ObjectSetInteger(0, "Yesterday", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Yesterday", OBJPROP_YDISTANCE, (long)(height/3.428571429));

   if(YesterdayProfit() >= 0)
   {
   ObjectCreate(0, "Prof2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof2",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Prof2",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(YesterdayProfit(),2),2));
   ObjectSetInteger(0, "Prof2", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof2", OBJPROP_YDISTANCE, (long)(height/3.428571429));
   }

   if(YesterdayProfit() < 0)
   {
   ObjectCreate(0, "Prof2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof2",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Prof2",OBJPROP_TEXT, DoubleToString(NormalizeDouble(YesterdayProfit(),2),2));
   ObjectSetInteger(0, "Prof2", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof2", OBJPROP_YDISTANCE, (long)(height/3.428571429));
   }
   
   if(YesterdayProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain2",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Gain2",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(YesterdayProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain2", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain2", OBJPROP_YDISTANCE, (long)(height/3.428571429));
   }

   if(YesterdayProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain2",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain2",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain2",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain2",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain2",OBJPROP_TEXT, DoubleToString(NormalizeDouble(YesterdayProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain2", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain2", OBJPROP_YDISTANCE, (long)(height/3.428571429));
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "Week",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Week",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Week",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Week",OBJPROP_COLOR, clrWhite); 
   ObjectSetString(0, "Week",OBJPROP_TEXT, "Week: ");
   ObjectSetInteger(0, "Week", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Week", OBJPROP_YDISTANCE, (long)(height/2.666666667));

   if(WeekProfit() >= 0)
   {
   ObjectCreate(0, "Prof3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof3",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof3",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof3",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Prof3",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(WeekProfit(),2),2));
   ObjectSetInteger(0, "Prof3", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof3", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }

   if(WeekProfit() < 0)
   {
   ObjectCreate(0, "Prof3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof3",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof3",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof3",OBJPROP_COLOR, clrOrangeRed);
   ObjectSetString(0, "Prof3",OBJPROP_TEXT, DoubleToString(NormalizeDouble(WeekProfit(),2),2));
   ObjectSetInteger(0, "Prof3", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof3", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }
   
   if(WeekProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain3",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain3",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain3",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Gain3",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(WeekProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain3", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain3", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }

   if(WeekProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain3",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain3",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain3",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain3",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain3",OBJPROP_TEXT, DoubleToString(NormalizeDouble(WeekProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain3", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain3", OBJPROP_YDISTANCE, (long)(height/2.666666667));
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "LastWeek",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastWeek",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastWeek",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastWeek",OBJPROP_COLOR, clrSilver); 
   ObjectSetString(0, "LastWeek",OBJPROP_TEXT, "LastWeek: ");
   ObjectSetInteger(0, "LastWeek", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "LastWeek", OBJPROP_YDISTANCE, (long)(height/2.181818182));

   if(LastWeekProfit() >= 0)
   {
   ObjectCreate(0, "Prof33",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof33",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof33",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof33",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Prof33",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(LastWeekProfit(),2),2));
   ObjectSetInteger(0, "Prof33", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof33", OBJPROP_YDISTANCE, (long)(height/2.181818182));
   }

   if(LastWeekProfit() < 0)
   {
   ObjectCreate(0, "Prof33",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof33",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof33",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof33",OBJPROP_COLOR, clrOrangeRed);
   ObjectSetString(0, "Prof33",OBJPROP_TEXT, DoubleToString(NormalizeDouble(LastWeekProfit(),2),2));
   ObjectSetInteger(0, "Prof33", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof33", OBJPROP_YDISTANCE, (long)(height/2.181818182));
   }
   
   if(LastWeekProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain33",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain33",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain33",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain33",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Gain33",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(LastWeekProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain33", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain33", OBJPROP_YDISTANCE, (long)(height/2.181818182));
   }

   if(LastWeekProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain33",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain33",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain33",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain33",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain33",OBJPROP_TEXT, DoubleToString(NormalizeDouble(LastWeekProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain33", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain33", OBJPROP_YDISTANCE, (long)(height/2.181818182));
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "Month",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Month",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Month",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Month",OBJPROP_COLOR, clrWhite); 
   ObjectSetString(0, "Month",OBJPROP_TEXT, "Month: ");
   ObjectSetInteger(0, "Month", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Month", OBJPROP_YDISTANCE, (long)(height/1.846153846));
 
   if(MonthProfit() >= 0)
   {
   ObjectCreate(0, "Prof4",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof4",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof4",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof4",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Prof4",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(MonthProfit(),2),2));
   ObjectSetInteger(0, "Prof4", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof4", OBJPROP_YDISTANCE, (long)(height/1.846153846));
   }

   if(MonthProfit() < 0)
   {
   ObjectCreate(0, "Prof4",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof4",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof4",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof4",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Prof4",OBJPROP_TEXT, DoubleToString(NormalizeDouble(MonthProfit(),2),2));
   ObjectSetInteger(0, "Prof4", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof4", OBJPROP_YDISTANCE, (long)(height/1.846153846));
   }
   
   if(MonthProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain4",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain4",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain4",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain4",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Gain4",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(MonthProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain4", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain4", OBJPROP_YDISTANCE, (long)(height/1.846153846)); 
   }

   if(MonthProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain4",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain4",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain4",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain4",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain4",OBJPROP_TEXT, DoubleToString(NormalizeDouble(MonthProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain4", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain4", OBJPROP_YDISTANCE, (long)(height/1.846153846)); 
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   ObjectCreate(0, "LastMonth",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "LastMonth",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "LastMonth",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "LastMonth",OBJPROP_COLOR, clrSilver); 
   ObjectSetString(0, "LastMonth",OBJPROP_TEXT, "LastMonth: ");
   ObjectSetInteger(0, "LastMonth", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "LastMonth", OBJPROP_YDISTANCE, (long)(height/1.6));
 
   if(LastMonthProfit() >= 0)
   {
   ObjectCreate(0, "Prof44",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof44",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof44",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof44",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Prof44",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(LastMonthProfit(),2),2));
   ObjectSetInteger(0, "Prof44", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof44", OBJPROP_YDISTANCE, (long)(height/1.6));
   }

   if(LastMonthProfit() < 0)
   {
   ObjectCreate(0, "Prof44",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof44",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Prof44",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Prof44",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Prof44",OBJPROP_TEXT, DoubleToString(NormalizeDouble(LastMonthProfit(),2),2));
   ObjectSetInteger(0, "Prof44", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof44", OBJPROP_YDISTANCE, (long)(height/1.6));
   }
   
   if(LastMonthProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain44",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain44",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain44",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain44",OBJPROP_COLOR, clrForestGreen); 
   ObjectSetString(0, "Gain44",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(LastMonthProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain44", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain44", OBJPROP_YDISTANCE, (long)(height/1.6)); 
   }

   if(LastMonthProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain44",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain44",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Gain44",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Gain44",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain44",OBJPROP_TEXT, DoubleToString(NormalizeDouble(LastMonthProfit()/Balance*100,2),2)+"%");
   ObjectSetInteger(0, "Gain44", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain44", OBJPROP_YDISTANCE, (long)(height/1.6)); 
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "Break7",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Break7",OBJPROP_FONT, FontName);
   ObjectSetInteger(0, "Break7",OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, "Break7",OBJPROP_COLOR, clrKhaki); 
   ObjectSetString(0, "Break7",OBJPROP_TEXT, "=========================================");
   ObjectSetInteger(0, "Break7", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Break7", OBJPROP_YDISTANCE, (long)(height/1.454545455));

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   ObjectCreate(0, "Overall",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Overall",OBJPROP_FONT, "Tahoma Bold");
   ObjectSetInteger(0, "Overall",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "Overall",OBJPROP_COLOR, clrSnow); 
   ObjectSetString(0, "Overall",OBJPROP_TEXT, "Overall: ");
   ObjectSetInteger(0, "Overall", OBJPROP_XDISTANCE, (long)(width/1.431223629));
   ObjectSetInteger(0, "Overall", OBJPROP_YDISTANCE, (long)(height/1.333333333)); 
   
   if(OverallProfit() >= 0)
   {
   ObjectCreate(0, "Prof5",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof5",OBJPROP_FONT, "Tahoma Bold");
   ObjectSetInteger(0, "Prof5",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "Prof5",OBJPROP_COLOR, clrGreenYellow); 
   ObjectSetString(0, "Prof5",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(OverallProfit(),2),2));
   ObjectSetInteger(0, "Prof5", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof5", OBJPROP_YDISTANCE, (long)(height/1.333333333));
   }

   if(OverallProfit() < 0)
   {
   ObjectCreate(0, "Prof5",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Prof5",OBJPROP_FONT, "Tahoma Bold");
   ObjectSetInteger(0, "Prof5",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "Prof5",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Prof5",OBJPROP_TEXT, DoubleToString(NormalizeDouble(OverallProfit(),2),2));
   ObjectSetInteger(0, "Prof5", OBJPROP_XDISTANCE, (long)(width/1.270411985));
   ObjectSetInteger(0, "Prof5", OBJPROP_YDISTANCE, (long)(height/1.333333333));
   }
   
   if(OverallProfit() >= 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain5",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain5",OBJPROP_FONT, "Tahoma Bold");
   ObjectSetInteger(0, "Gain5",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "Gain5",OBJPROP_COLOR, clrGreenYellow); 
   ObjectSetString(0, "Gain5",OBJPROP_TEXT, "+"+DoubleToString(NormalizeDouble(OverallProfit()/Balance*100,2),2)+" %");
   ObjectSetInteger(0, "Gain5", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain5", OBJPROP_YDISTANCE, (long)(height/1.333333333));           
   }

   if(OverallProfit() < 0 && Balance != 0)
   {
   ObjectCreate(0, "Gain5",OBJ_LABEL, 1, 0, 0);
   ObjectSetString(0, "Gain5",OBJPROP_FONT, "Tahoma Bold");
   ObjectSetInteger(0, "Gain5",OBJPROP_FONTSIZE, SecondaryFontSize);
   ObjectSetInteger(0, "Gain5",OBJPROP_COLOR, clrOrangeRed); 
   ObjectSetString(0, "Gain5",OBJPROP_TEXT, DoubleToString(NormalizeDouble(OverallProfit()/Balance*100,2),2)+" %");
   ObjectSetInteger(0, "Gain5", OBJPROP_XDISTANCE, (long)(width/1.142087542));
   ObjectSetInteger(0, "Gain5", OBJPROP_YDISTANCE, (long)(height/1.333333333));           
   }
       
//--- return value of prev_calculated for next call

   return(rates_total);
  }

void OnTick()
{
   ChartSetSymbolPeriod(0,NULL,0);
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   int CountBuyPositions()
   {
      int NumberOfBuys = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
            
            if(!CompoundResults && _Symbol == CurrencyPair && PositionDirection == POSITION_TYPE_BUY)
               {
                  NumberOfBuys = NumberOfBuys + 1;
               }
            
            if(CompoundResults && PositionDirection == POSITION_TYPE_BUY)
               {
                  NumberOfBuys = NumberOfBuys + 1;
               }               
         }
      
      return NumberOfBuys;   
   } 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   int CountSellPositions()
   {
      int NumberOfSells = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
            
            if(!CompoundResults && _Symbol == CurrencyPair && PositionDirection == POSITION_TYPE_SELL)
               {
                  NumberOfSells = NumberOfSells + 1;
               }
            if(CompoundResults && PositionDirection == POSITION_TYPE_SELL)
               {
                  NumberOfSells = NumberOfSells + 1;
               }               
         }
      
      return NumberOfSells;   
   }      

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
   double LongsProfit()
   {
   
   double currentProfit = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
     
      ulong ticket = PositionGetTicket(i);
      ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
      
      if(ticket > 0)
        {               
         if(!CompoundResults && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionDirection == POSITION_TYPE_BUY)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }
         if(CompoundResults && PositionDirection == POSITION_TYPE_BUY)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }           
        }
     }
   return currentProfit;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   double ShortsProfit()
   {
   
   double currentProfit = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
     
      ulong ticket = PositionGetTicket(i);
      ulong PositionDirection = PositionGetInteger(POSITION_TYPE);
      
      if(ticket > 0)
        {               
         if(!CompoundResults && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionDirection == POSITION_TYPE_SELL)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }
         if(CompoundResults && PositionDirection == POSITION_TYPE_SELL)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }           
        }
     }
   return currentProfit;
   } 
   
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   double TodayProfit()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";
      double MyResult = 0;
      ulong DealDirection = 0;
      
      datetime end = TimeCurrent();                 
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
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               
               if (!CompoundResults && MySymbol == _Symbol && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
               
               if (CompoundResults && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }               
            }
         }
      return MyResult;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               
               if (!CompoundResults && MySymbol == _Symbol && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
               
               if (CompoundResults && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
            }
         }
      return MyResult;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   double WeekProfit()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";
      double MyResult = 0;
      ulong DealDirection = 0;         
      
      datetime end = TimeCurrent();                 
      datetime start = end - PeriodSeconds(PERIOD_W1);     
      
      HistorySelect(start, end);
      for(uint i=0; i < TotalNumberOfDeals - TicketNumber; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               DealDirection = HistoryDealGetInteger(TicketNumber,DEAL_TYPE);
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               
               if (!CompoundResults && MySymbol == _Symbol && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
               
               if (CompoundResults && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
            }
         }
      return MyResult;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   double LastWeekProfit()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";
      double MyResult = 0;
      ulong DealDirection = 0;         
      
      datetime end = TimeCurrent() - PeriodSeconds(PERIOD_W1);                 
      datetime start = end - PeriodSeconds(PERIOD_W1);     
      
      HistorySelect(start, end);
      for(uint i=0; i < TotalNumberOfDeals - TicketNumber; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               DealDirection = HistoryDealGetInteger(TicketNumber,DEAL_TYPE);
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               
               if (!CompoundResults && MySymbol == _Symbol && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
               
               if (CompoundResults && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
            }
         }
      return MyResult;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   double MonthProfit()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";
      double MyResult = 0;
      ulong DealDirection = 0;         
      
      datetime end = TimeCurrent();                 
      datetime start = end - PeriodSeconds(PERIOD_MN1);
      
      HistorySelect(start, end);
      for(uint i=0; i < TotalNumberOfDeals - TicketNumber; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               DealDirection = HistoryDealGetInteger(TicketNumber,DEAL_TYPE);
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               
               if (!CompoundResults && MySymbol == _Symbol && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
               
               if (CompoundResults && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
            }
         }
      return MyResult;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   double LastMonthProfit()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";
      double MyResult = 0;
      ulong DealDirection = 0;         
      
      datetime end = TimeCurrent() - PeriodSeconds(PERIOD_MN1);                 
      datetime start = end - PeriodSeconds(PERIOD_MN1);
      
      HistorySelect(start, end);
      for(uint i=0; i < TotalNumberOfDeals - TicketNumber; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               DealDirection = HistoryDealGetInteger(TicketNumber,DEAL_TYPE);
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               
               if (!CompoundResults && MySymbol == _Symbol && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
               
               if (CompoundResults && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
            }
         }
      return MyResult;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

   double OverallProfit()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";
      double MyResult = 0;
      ulong DealDirection = 0;         
      
      datetime end = TimeCurrent();                 
      datetime start = 0;     
      
      HistorySelect(start, end);
      for(uint i=0; i < TotalNumberOfDeals - TicketNumber; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               DealDirection = HistoryDealGetInteger(TicketNumber,DEAL_TYPE);
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               
               if (!CompoundResults && MySymbol == _Symbol && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
               
               if (CompoundResults && OrderProfit != 0 && (DealDirection == DEAL_TYPE_BUY || DealDirection == DEAL_TYPE_SELL))              
               {
  
                  MyResult += OrderProfit + Commission + Swap;
               
               }
            }
         }
      return MyResult;
   }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------      