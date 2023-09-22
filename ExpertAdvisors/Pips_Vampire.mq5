// 1 - Playing since 8:00 EST, sell only when lines ichi in good order for buy + price below them

   #include <Trade/Trade.mqh>

   CTrade trade;

   bool isPriceBelowEURJPY = false;
   bool isTsKsCrossDEURJPY = false;  

   bool isPriceBelowEURUSD = false;
   bool isTsKsCrossDEURUSD = false;
   
   bool isPriceBelowGBPJPY = false;
   bool isTsKsCrossDGBPJPY = false;
   
   bool isPriceBelowGBPUSD = false;
   bool isTsKsCrossDGBPUSD = false;
   
   bool isEApVamp = true;
   
   bool isTimeForTradeEURJPY = false;
   bool isTimeForTradeEURUSD = false;
   bool isTimeForTradeGBPJPY = false;
   bool isTimeForTradeGBPUSD = false;
   
   input double AccountBalance = 1000;
     
   input int MyTSSValue = 7;                 // Tenkan Value
   input int MySSSValue = 28;                // Kijun Value
   input int MySSBValue = 119;               // SSB Value
   
   input double FixedStop = 40;              // StopLoss is 30/1000 -> 3% sl +10 spread = 40
   double CurrencyCorrectorJPY = 100;        // Depends on how many digits currency have -> for 3 digits (JPY) it is 100 -> for 5 digits it is 10000 so -> """ (digits - 1) = amount of "0" after 1 """
   double CurrencyCorrectorUSD = 10000;
   
   double PointJPY = 0.001;                  // Replaces _Point function
   double PointUSD = 0.00001;
   
   double DigitsJPY = 3;                     // Replaces _Digits function
   double DigitsUSD = 5;
  
   input double AtrMultiplierEURJPY = 1.28;  // ATR Multiplier for SL EURJPY
   input double AtrMultiplierEURUSD = 1.04;  // ATR Multiplier for SL EURUSD
   input double AtrMultiplierGBPJPY = 0.80;  // ATR Multiplier for SL GBPJPY
   input double AtrMultiplierGBPUSD = 1.54;  // ATR Multiplier for SL GBPUSD   
   
   input double AtrScope = 250;              // ATR up to 100
   input double EqPercentTr = 0.03;          // Equity Percentage Trailing Sl
   input double TrailSlVal = 3000;           // It is GAP between current price and SL

void OnTick()
  {
   
   //+------------------------------------------------------------------+
   //| Prices                                                           |
   //+------------------------------------------------------------------+
   
   double EURJPYBid = NormalizeDouble(SymbolInfoDouble("EURJPY", SYMBOL_BID), DigitsJPY);
   double EURJPYAsk = NormalizeDouble(SymbolInfoDouble("EURJPY", SYMBOL_ASK), DigitsJPY);
   
   double EURUSDBid = NormalizeDouble(SymbolInfoDouble("EURUSD", SYMBOL_BID), DigitsUSD);
   double EURUSDAsk = NormalizeDouble(SymbolInfoDouble("EURUSD", SYMBOL_ASK), DigitsUSD);

   double GBPJPYBid = NormalizeDouble(SymbolInfoDouble("GBPJPY", SYMBOL_BID), DigitsJPY);
   double GBPJPYAsk = NormalizeDouble(SymbolInfoDouble("GBPJPY", SYMBOL_ASK), DigitsJPY);
   
   double GBPUSDBid = NormalizeDouble(SymbolInfoDouble("GBPUSD", SYMBOL_BID), DigitsUSD);
   double GBPUSDAsk = NormalizeDouble(SymbolInfoDouble("GBPUSD", SYMBOL_ASK), DigitsUSD);
   
   double cProfitEURJPY = CurrentProfitEURJPY();  
   double AccountBalanceInfoEURJPY = AccountBalanceEURJPY();
   double AccountEquityInfoEURJPY = AccountEquityEURJPY(AccountBalanceInfoEURJPY, cProfitEURJPY);
   
   double cProfitEURUSD = CurrentProfitEURUSD();
   double AccountBalanceInfoEURUSD = AccountBalanceEURUSD();
   double AccountEquityInfoEURUSD = AccountEquityEURUSD(AccountBalanceInfoEURUSD, cProfitEURUSD);
   
   double cProfitGBPJPY = CurrentProfitGBPJPY();  
   double AccountBalanceInfoGBPJPY = AccountBalanceGBPJPY();
   double AccountEquityInfoGBPJPY = AccountEquityGBPJPY(AccountBalanceInfoGBPJPY, cProfitGBPJPY);
   
   double cProfitGBPUSD = CurrentProfitGBPUSD();
   double AccountBalanceInfoGBPUSD = AccountBalanceGBPUSD();
   double AccountEquityInfoGBPUSD = AccountEquityGBPUSD(AccountBalanceInfoGBPUSD, cProfitGBPUSD);
    
   string signalEURJPY = "";
   string signalEURUSD = "";  
   string signalGBPJPY = "";
   string signalGBPUSD = "";   
  
   datetime timeEURJPY = iTime("EURJPY", PERIOD_M1, 0);
   string HoursAndMinutesEURJPY = TimeToString(timeEURJPY, TIME_MINUTES);
   isTimeForTradeEURJPY = StringSubstr(HoursAndMinutesEURJPY, 0, 5) == "08:00";
   
   datetime timeEURUSD = iTime("EURUSD", PERIOD_M1, 0);
   string HoursAndMinutesEURUSD = TimeToString(timeEURUSD, TIME_MINUTES);
   isTimeForTradeEURUSD = StringSubstr(HoursAndMinutesEURUSD, 0, 5) == "08:00";
   
   datetime timeGBPJPY = iTime("GBPJPY", PERIOD_M1, 0);
   string HoursAndMinutesGBPJPY = TimeToString(timeGBPJPY, TIME_MINUTES);
   isTimeForTradeGBPJPY = StringSubstr(HoursAndMinutesGBPJPY, 0, 5) == "08:00";
   
   datetime timeGBPUSD = iTime("GBPUSD", PERIOD_M1, 0);
   string HoursAndMinutesGBPUSD = TimeToString(timeGBPUSD, TIME_MINUTES);
   isTimeForTradeGBPUSD = StringSubstr(HoursAndMinutesGBPUSD, 0, 5) == "08:00";
  
   MqlRates PriceInfoEURJPY[];
   ArraySetAsSeries (PriceInfoEURJPY, true);
   int DataEURJPY = CopyRates ("EURJPY", PERIOD_H1, 0, (MySSBValue+3), PriceInfoEURJPY);
   
   MqlRates PriceInfoEURUSD[];
   ArraySetAsSeries (PriceInfoEURUSD, true);
   int DataEURUSD = CopyRates ("EURUSD", PERIOD_H1, 0, (MySSBValue+3), PriceInfoEURUSD);
   
   MqlRates PriceInfoGBPJPY[];
   ArraySetAsSeries (PriceInfoGBPJPY, true);
   int DataGBPJPY = CopyRates ("GBPJPY", PERIOD_H4, 0, (MySSBValue+3), PriceInfoGBPJPY);
   
   MqlRates PriceInfoGBPUSD[];
   ArraySetAsSeries (PriceInfoGBPUSD, true);
   int DataGBPUSD = CopyRates ("GBPUSD", PERIOD_H1, 0, (MySSBValue+3), PriceInfoGBPUSD);    
   
  //+------------------------------------------------------------------+
  //| ATR EURJPY                                                       |
  //+------------------------------------------------------------------+
   
   double ATRValueEURJPY[];                   
   int ATRHandleEURJPY = iATR("EURJPY", PERIOD_H1, AtrScope); 
   ArraySetAsSeries( ATRValueEURJPY, true );
   if(CopyBuffer(ATRHandleEURJPY, 0, 0, 5, ATRValueEURJPY) > 0);

   double AtrEURJPY = ATRValueEURJPY[0];
   
   double IntervalEURJPY = AtrMultiplierEURJPY*AtrEURJPY*CurrencyCorrectorJPY;
   
   // ** Error Handler **
   
   if(IntervalEURJPY == 0)
   {
      IntervalEURJPY = 30;
   }
   
  //+------------------------------------------------------------------+
  //| ATR EURUSD                                                       |
  //+------------------------------------------------------------------+
   
   double ATRValueEURUSD[];                   
   int ATRHandleEURUSD = iATR("EURUSD", PERIOD_H1, AtrScope); 
   ArraySetAsSeries( ATRValueEURUSD, true );
   if(CopyBuffer(ATRHandleEURUSD, 0, 0, 5, ATRValueEURUSD) > 0);

   double AtrEURUSD = ATRValueEURUSD[0];
   
   double IntervalEURUSD = AtrMultiplierEURUSD*AtrEURUSD*CurrencyCorrectorUSD;
   
   // ** Error Handler **
   
   if(IntervalEURUSD == 0)
   {
      IntervalEURUSD = 30;
   }   

  //+------------------------------------------------------------------+
  //| ATR GBPJPY                                                       |
  //+------------------------------------------------------------------+
   
   double ATRValueGBPJPY[];                   
   int ATRHandleGBPJPY = iATR("GBPJPY", PERIOD_H4, AtrScope); 
   ArraySetAsSeries( ATRValueGBPJPY, true );
   if(CopyBuffer(ATRHandleGBPJPY, 0, 0, 5, ATRValueGBPJPY) > 0);

   double AtrGBPJPY = ATRValueGBPJPY[0];
   
   double IntervalGBPJPY = AtrMultiplierGBPJPY*AtrGBPJPY*CurrencyCorrectorJPY;
   
   // ** Error Handler **
   
   if(IntervalGBPJPY == 0)
   {
      IntervalGBPJPY = 30;
   }
   
  //+------------------------------------------------------------------+
  //| ATR GBPUSD                                                       |
  //+------------------------------------------------------------------+
   
   double ATRValueGBPUSD[];                   
   int ATRHandleGBPUSD = iATR("GBPUSD", PERIOD_H1, AtrScope); 
   ArraySetAsSeries( ATRValueGBPUSD, true );
   if(CopyBuffer(ATRHandleGBPUSD, 0, 0, 5, ATRValueGBPUSD) > 0);

   double AtrGBPUSD = ATRValueGBPUSD[0];
   
   double IntervalGBPUSD = AtrMultiplierGBPUSD*AtrGBPUSD*CurrencyCorrectorUSD;
   
   // ** Error Handler **
   
   if(IntervalGBPUSD == 0)
   {
      IntervalGBPUSD = 30;
   }
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss EURJPY                                      |
   //+------------------------------------------------------------------+   
 
   double xEURJPY = FixedStop/(IntervalEURJPY*10);
   double LotSizeEURJPY = NormalizeDouble(xEURJPY, 2);
     
   double slEURJPY = (IntervalEURJPY + 1)*10;  
      
   double stopSEURJPY = EURJPYBid + ((IntervalEURJPY + slEURJPY)*PointJPY);
     
   double AutoTrailEURJPY = (1 + EqPercentTr)*AccountBalanceInfoEURJPY;                          
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss EURUSD                                      |
   //+------------------------------------------------------------------+   
 
   double xEURUSD = FixedStop/(IntervalEURUSD*10);
   double LotSizeEURUSD = NormalizeDouble(xEURUSD, 2);
     
   double slEURUSD = (IntervalEURUSD + 1)*10; 
      
   double stopSEURUSD = EURUSDBid + ((IntervalEURUSD + slEURUSD)*PointUSD);
     
   double AutoTrailEURUSD = (1 + EqPercentTr)*AccountBalanceInfoEURUSD;                                    

   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss GBPJPY                                      |
   //+------------------------------------------------------------------+   
 
   double xGBPJPY = FixedStop/(IntervalGBPJPY*10);
   double LotSizeGBPJPY = NormalizeDouble(xGBPJPY, 2);
     
   double slGBPJPY = (IntervalGBPJPY + 1)*10;  
      
   double stopSGBPJPY = GBPJPYBid + ((IntervalGBPJPY + slGBPJPY)*PointJPY);
     
   double AutoTrailGBPJPY = (1 + EqPercentTr)*AccountBalanceInfoGBPJPY;                          
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss GBPUSD                                      |
   //+------------------------------------------------------------------+   
 
   double xGBPUSD = FixedStop/(IntervalGBPUSD*10);
   double LotSizeGBPUSD = NormalizeDouble(xGBPUSD, 2);
     
   double slGBPUSD = (IntervalGBPUSD + 1)*10; 
      
   double stopSGBPUSD = GBPUSDBid + ((IntervalGBPUSD + slGBPUSD)*PointUSD);
     
   double AutoTrailGBPUSD = (1 + EqPercentTr)*AccountBalanceInfoGBPUSD;
   
   //+------------------------------------------------------------------+
   //| Ichimoku EURJPY                                                  |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinitionEURJPY = iIchimoku("EURJPY", PERIOD_H1, MyTSSValue, MySSSValue, MySSBValue);
   
   double TenkanArrayEURJPY[];
   ArraySetAsSeries(TenkanArrayEURJPY, true);
   CopyBuffer(IchimokuDefinitionEURJPY, 0, 0, (MySSSValue+3), TenkanArrayEURJPY);
   double TenkanValueEURJPY = TenkanArrayEURJPY[1]; 
   
   double KijunArrayEURJPY[];
   ArraySetAsSeries(KijunArrayEURJPY, true);
   CopyBuffer(IchimokuDefinitionEURJPY, 1, 0, (MySSSValue+3), KijunArrayEURJPY);
   double KijunValueEURJPY = KijunArrayEURJPY[1];
   
   //+------------------------------------------------------------------+
   //| Ichimoku EURUSD                                                  |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinitionEURUSD = iIchimoku("EURUSD", PERIOD_H1, MyTSSValue, MySSSValue, MySSBValue);
   
   double TenkanArrayEURUSD[];
   ArraySetAsSeries(TenkanArrayEURUSD, true);
   CopyBuffer(IchimokuDefinitionEURUSD, 0, 0, (MySSSValue+3), TenkanArrayEURUSD);
   double TenkanValueEURUSD = TenkanArrayEURUSD[1];
   double TenkanValueEURUSD2 = TenkanArrayEURUSD[2];   
   
   double KijunArrayEURUSD[];
   ArraySetAsSeries(KijunArrayEURUSD, true);
   CopyBuffer(IchimokuDefinitionEURUSD, 1, 0, (MySSSValue+3), KijunArrayEURUSD);
   double KijunValueEURUSD = KijunArrayEURUSD[1]; 
   double KijunValueEURUSD2 = KijunArrayEURUSD[2];   

   //+------------------------------------------------------------------+
   //| Ichimoku GBPJPY                                                  |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinitionGBPJPY = iIchimoku("GBPJPY", PERIOD_H4, MyTSSValue, MySSSValue, MySSBValue);
   
   double TenkanArrayGBPJPY[];
   ArraySetAsSeries(TenkanArrayGBPJPY, true);
   CopyBuffer(IchimokuDefinitionGBPJPY, 0, 0, (MySSSValue+3), TenkanArrayGBPJPY);
   double TenkanValueGBPJPY = TenkanArrayGBPJPY[1];
   double TenkanValueGBPJPY2 = TenkanArrayGBPJPY[2]; 
   
   double KijunArrayGBPJPY[];
   ArraySetAsSeries(KijunArrayGBPJPY, true);
   CopyBuffer(IchimokuDefinitionGBPJPY, 1, 0, (MySSSValue+3), KijunArrayGBPJPY);
   double KijunValueGBPJPY = KijunArrayGBPJPY[1];
   double KijunValueGBPJPY2 = KijunArrayGBPJPY[2];
   
   //+------------------------------------------------------------------+
   //| Ichimoku GBPUSD                                                  |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinitionGBPUSD = iIchimoku("GBPUSD", PERIOD_H1, MyTSSValue, MySSSValue, MySSBValue);
   
   double TenkanArrayGBPUSD[];
   ArraySetAsSeries(TenkanArrayGBPUSD, true);
   CopyBuffer(IchimokuDefinitionGBPUSD, 0, 0, (MySSSValue+3), TenkanArrayGBPUSD);
   double TenkanValueGBPUSD = TenkanArrayGBPUSD[1];   
   
   double KijunArrayGBPUSD[];
   ArraySetAsSeries(KijunArrayGBPUSD, true);
   CopyBuffer(IchimokuDefinitionGBPUSD, 1, 0, (MySSSValue+3), KijunArrayGBPUSD);
   double KijunValueGBPUSD = KijunArrayGBPUSD[1]; 
   
   //+------------------------------------------------------------------+
   //| Ts Ks Cross EURJPY                                               |
   //+------------------------------------------------------------------+  
   
   if(!isTsKsCrossDEURJPY)
   if(TenkanValueEURJPY < KijunValueEURJPY)
   {
      isTsKsCrossDEURJPY = true;
   }
   
   if(isTsKsCrossDEURJPY)
   if(TenkanValueEURJPY > KijunValueEURJPY)
   {
      isTsKsCrossDEURJPY = false;
   }
   
   //+------------------------------------------------------------------+
   //| Ts Ks Cross EURUSD                                               |
   //+------------------------------------------------------------------+  
   
   if(!isTsKsCrossDEURUSD)
   if(TenkanValueEURUSD2 > KijunValueEURUSD2)
   if(TenkanValueEURUSD < KijunValueEURUSD)
   {
      isTsKsCrossDEURUSD = true;
   }
   
   if(isTsKsCrossDEURUSD)
   if(TenkanValueEURUSD > KijunValueEURUSD)
   {
      isTsKsCrossDEURUSD = false;
   }

   //+------------------------------------------------------------------+
   //| Ts Ks Cross GBPJPY                                               |
   //+------------------------------------------------------------------+  
   
   if(!isTsKsCrossDGBPJPY)
   if(TenkanValueGBPJPY2 > KijunValueGBPJPY2)
   if(TenkanValueGBPJPY < KijunValueGBPJPY)
   {
      isTsKsCrossDGBPJPY = true;
   }
   
   if(isTsKsCrossDGBPJPY)
   if(TenkanValueGBPJPY > KijunValueGBPJPY)
   {
      isTsKsCrossDGBPJPY = false;
   }
   
   //+------------------------------------------------------------------+
   //| Ts Ks Cross GBPUSD                                               |
   //+------------------------------------------------------------------+  
   
   if(!isTsKsCrossDGBPUSD)
   if(TenkanValueGBPUSD < KijunValueGBPUSD)
   {
      isTsKsCrossDGBPUSD = true;
   }
   
   if(isTsKsCrossDGBPUSD)
   if(TenkanValueGBPUSD > KijunValueGBPUSD)
   {
      isTsKsCrossDGBPUSD = false;
   } 
   
   //+------------------------------------------------------------------+
   //| Sell EURJPY                                                      |
   //+------------------------------------------------------------------+
   
   if(!isPriceBelowEURJPY)
   if(PriceInfoEURJPY[1].close < TenkanValueEURJPY && PriceInfoEURJPY[1].close < KijunValueEURJPY)
   {
      isPriceBelowEURJPY = true;
   }      
   
   if(isPriceBelowEURJPY)
   if(PriceInfoEURJPY[1].close > TenkanValueEURJPY || PriceInfoEURJPY[1].close > KijunValueEURJPY)
   {
      isPriceBelowEURJPY = false;
   }  
       
   if(isTimeForTradeEURJPY)
   if(isPriceBelowEURJPY)
   if(isTsKsCrossDEURJPY)  
   {  
      isPriceBelowEURJPY = false;
      signalEURJPY = "sellEURJPY";
   }   
   
   //+------------------------------------------------------------------+
   //| Sell EURUSD                                                      |
   //+------------------------------------------------------------------+
   
   if(!isPriceBelowEURUSD)
   if(PriceInfoEURUSD[1].close < TenkanValueEURUSD && PriceInfoEURUSD[1].close < KijunValueEURUSD)
   {
      isPriceBelowEURUSD = true;
   }      
   
   if(isPriceBelowEURUSD)
   if(PriceInfoEURUSD[1].close > TenkanValueEURUSD || PriceInfoEURUSD[1].close > KijunValueEURUSD)
   {
      isPriceBelowEURUSD = false;
   }  
     
   if(isTimeForTradeEURUSD)  
   if(isPriceBelowEURUSD)
   if(isTsKsCrossDEURUSD)     
   {
      isPriceBelowEURUSD = false;    
      signalEURUSD = "sellEURUSD";           
   }    

   //+------------------------------------------------------------------+
   //| Sell GBPJPY                                                      |
   //+------------------------------------------------------------------+
   
   if(!isPriceBelowGBPJPY)
   if(PriceInfoGBPJPY[1].close < TenkanValueGBPJPY && PriceInfoGBPJPY[1].close < KijunValueGBPJPY)
   {
      isPriceBelowGBPJPY = true;
   }      
   
   if(isPriceBelowGBPJPY)
   if(PriceInfoGBPJPY[1].close > TenkanValueGBPJPY || PriceInfoGBPJPY[1].close > KijunValueGBPJPY)
   {
      isPriceBelowGBPJPY = false;
   }  
       
   if(isTimeForTradeGBPJPY)
   if(isPriceBelowGBPJPY)
   if(isTsKsCrossDGBPJPY)  
   {  
      isPriceBelowGBPJPY = false;
      signalGBPJPY = "sellGBPJPY";
   }
      
   //+------------------------------------------------------------------+
   //| Sell GBPUSD                                                      |
   //+------------------------------------------------------------------+
   
   if(!isPriceBelowGBPUSD)
   if(PriceInfoGBPUSD[1].close < TenkanValueGBPUSD && PriceInfoGBPUSD[1].close < KijunValueGBPUSD)
   {
      isPriceBelowGBPUSD = true;
   }      
   
   if(isPriceBelowGBPUSD)
   if(PriceInfoGBPUSD[1].close > TenkanValueGBPUSD || PriceInfoGBPUSD[1].close > KijunValueGBPUSD)
   {
      isPriceBelowGBPUSD = false;
   }  
     
   if(isTimeForTradeGBPUSD)  
   if(isPriceBelowGBPUSD)
   if(isTsKsCrossDGBPUSD)     
   {
      isPriceBelowGBPUSD = false;    
      signalGBPUSD = "sellGBPUSD";           
   }
   
   //+------------------------------------------------------------------+
   //| Trades EURJPY                                                    |
   //+------------------------------------------------------------------+
  
   //                  *** Sell ***
   
//   if(signalEURJPY == "sellEURJPY" && CountPositionsPerEA_EURJPY() < 1)
//   {
//      trade.Sell(LotSizeEURJPY, "EURJPY", EURJPYBid, stopSEURJPY, NULL, NULL);      
//   }        
//   
//   CheckSellTrailingSlEURJPY(EURJPYBid, AccountEquityInfoEURJPY, AutoTrailEURJPY, AtrEURJPY);  
   
   //+------------------------------------------------------------------+
   //| Trades EURUSD                                                    |
   //+------------------------------------------------------------------+
  
   //                  *** Sell ***
   
//   if(signalEURUSD == "sellEURUSD" && CountPositionsPerEA_EURUSD() < 1)
//   {
//      trade.Sell(LotSizeEURUSD, "EURUSD", EURUSDBid, stopSEURUSD, NULL, NULL);      
//   }        
//   
//   CheckSellTrailingSlEURUSD(EURUSDBid, AccountEquityInfoEURUSD, AutoTrailEURUSD, AtrEURUSD);
   
   //+------------------------------------------------------------------+
   //| Trades GBPJPY                                                    |
   //+------------------------------------------------------------------+
  
   //                  *** Sell ***
   
   if(signalGBPJPY == "sellGBPJPY" && CountPositionsPerEA_GBPJPY() < 1)
   {
      trade.Sell(LotSizeGBPJPY, "GBPJPY", GBPJPYBid, stopSGBPJPY, NULL, NULL);      
   }        
   
   CheckSellTrailingSlGBPJPY(GBPJPYBid, AccountEquityInfoGBPJPY, AutoTrailGBPJPY, AtrGBPJPY);  
   
   //+------------------------------------------------------------------+
   //| Trades GBPUSD                                                    |
   //+------------------------------------------------------------------+
  
   //                  *** Sell ***
   
//   if(signalGBPUSD == "sellGBPUSD" && CountPositionsPerEA_GBPUSD() < 1)
//   {
//      trade.Sell(LotSizeGBPUSD, "GBPUSD", GBPUSDBid, stopSGBPUSD, NULL, NULL);      
//   }        
//   
//   CheckSellTrailingSlGBPUSD(GBPUSDBid, AccountEquityInfoGBPUSD, AutoTrailGBPUSD, AtrGBPUSD);       
   
   //Comment("\nBalance EURJPY: ", AccountBalanceEURJPY(),
   //        "\nEquity EURJPY: ", AccountEquityEURJPY(AccountBalanceInfoEURJPY, cProfitEURJPY),
   //        "\nBalance GBPJPY: ", AccountBalanceGBPJPY(),
   //        "\nEquity GBPJPY: ", AccountEquityGBPJPY(AccountBalanceInfoGBPJPY, cProfitGBPJPY),
   //        "\nBalance EURUSD: ", AccountBalanceEURUSD(),
   //        "\nEquity EURUSD: ", AccountEquityEURUSD(AccountBalanceInfoEURUSD, cProfitEURUSD),
   //        "\nBalance GBPUSD: ", AccountBalanceGBPUSD(),
   //        "\nEquity GBPUSD: ", AccountEquityGBPUSD(AccountBalanceInfoGBPUSD, cProfitGBPUSD));                     
                         
  }            
  
   //+------------------------------------------------------------------+
   //| Money Management Handlers EURJPY                                 |
   //+------------------------------------------------------------------+
 
 void CheckSellTrailingSlEURJPY (double EURJPYBid, double AccountEquityInfoEURJPY, double AutoTrailEURJPY, double AtrEURJPY)
   {
                
      double SL = NormalizeDouble(EURJPYBid + 2*AtrEURJPY, DigitsJPY);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("EURJPY" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(AccountEquityInfoEURJPY >= AutoTrailEURJPY)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*PointJPY), NULL);
          }   
        }  
      }   
   }


   int CountPositionsPerEA_EURJPY()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("EURJPY" == CurrencyPair && isEApVamp)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }
   
   double CurrentProfitEURJPY()
   {
   
   double currentProfit = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
     
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0)
        {               
         if(PositionGetString(POSITION_SYMBOL) == "EURJPY" && isEApVamp)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }
        }
     }
   return currentProfit;
   }   
   
   double AccountBalanceEURJPY()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";     
      double MyResult = AccountBalance;
      double BalanceEURJPY = AccountBalance;     
      
      HistorySelect(0, TimeCurrent());
      for(uint i=0; i < TotalNumberOfDeals; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);              
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               
               if (MySymbol == "EURJPY" && isEApVamp && OrderProfit != 0)              
               {
  
                  MyResult = BalanceEURJPY + OrderProfit + Commission + Swap;
                  BalanceEURJPY = MyResult;
               
               }
            }
         }
      return MyResult;
   }       

   double AccountEquityEURJPY(double AccountBalanceInfoEURJPY, double cProfitEURJPY)
   {
     
   double MyResult = AccountBalanceInfoEURJPY + cProfitEURJPY;
   
   if(PositionGetString(POSITION_SYMBOL) == "EURJPY" && isEApVamp)
   if(cProfitEURJPY == 0)
      {
         MyResult = AccountBalanceInfoEURJPY;
      }
   
   return MyResult;
   
   }
      
   //+------------------------------------------------------------------+
   //| Money Management Handlers EURUSD                                 |
   //+------------------------------------------------------------------+
 
 void CheckSellTrailingSlEURUSD (double EURUSDBid, double Equity, double AutoTrailEURUSD, double AtrEURUSD)
   {
                
      double SL = NormalizeDouble(EURUSDBid + 2*AtrEURUSD, DigitsUSD);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("EURUSD" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(Equity >= AutoTrailEURUSD)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*PointUSD), NULL);
          }   
        }  
      }   
   }
   
   
   int CountPositionsPerEA_EURUSD()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("EURUSD" == CurrencyPair && isEApVamp)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }
   
   
   double CurrentProfitEURUSD()
   {
   
   double currentProfit = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
     
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0)
        {               
         if(PositionGetString(POSITION_SYMBOL) == "EURUSD" && isEApVamp)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }
        }
     }
   return currentProfit;
   }   
   
   double AccountBalanceEURUSD()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";     
      double MyResult = AccountBalance;
      double BalanceEURUSD = AccountBalance;     
      
      HistorySelect(0, TimeCurrent());
      for(uint i=0; i < TotalNumberOfDeals; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);              
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               
               if (MySymbol == "EURUSD" && isEApVamp && OrderProfit != 0)              
               {
  
                  MyResult = BalanceEURUSD + OrderProfit + Commission + Swap;
                  BalanceEURUSD = MyResult;
               
               }
            }
         }
      return MyResult;
   }       

   double AccountEquityEURUSD(double AccountBalanceInfoEURUSD, double cProfitEURUSD)
   {
   
   double MyResult = AccountBalanceInfoEURUSD + cProfitEURUSD;
   
   if(PositionGetString(POSITION_SYMBOL) == "EURUSD" && isEApVamp)
   if(cProfitEURUSD == 0)
      {
         MyResult = AccountBalanceInfoEURUSD;
      }
   
   return MyResult;
   
   }             

   //+------------------------------------------------------------------+
   //| Money Management Handlers GBPJPY                                 |
   //+------------------------------------------------------------------+
 
 void CheckSellTrailingSlGBPJPY (double GBPJPYBid, double AccountEquityInfoGBPJPY, double AutoTrailGBPJPY, double AtrGBPJPY)
   {
                
      double SL = NormalizeDouble(GBPJPYBid + 2*AtrGBPJPY, DigitsJPY);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("GBPJPY" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(AccountEquityInfoGBPJPY >= AutoTrailGBPJPY)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*PointJPY), NULL);
          }   
        }  
      }   
   }


   int CountPositionsPerEA_GBPJPY()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("GBPJPY" == CurrencyPair && isEApVamp)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }
   
   double CurrentProfitGBPJPY()
   {
   
   double currentProfit = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
     
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0)
        {               
         if(PositionGetString(POSITION_SYMBOL) == "GBPJPY" && isEApVamp)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }
        }
     }
   return currentProfit;
   }   
   
   double AccountBalanceGBPJPY()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";     
      double MyResult = AccountBalance;
      double BalanceGBPJPY = AccountBalance;     
      
      HistorySelect(0, TimeCurrent());
      for(uint i=0; i < TotalNumberOfDeals; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);              
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               
               if (MySymbol == "GBPJPY" && isEApVamp && OrderProfit != 0)              
               {
  
                  MyResult = BalanceGBPJPY + OrderProfit + Commission + Swap;
                  BalanceGBPJPY = MyResult;
               
               }
            }
         }
      return MyResult;
   }       

   double AccountEquityGBPJPY(double AccountBalanceInfoGBPJPY, double cProfitGBPJPY)
   {
     
   double MyResult = AccountBalanceInfoGBPJPY + cProfitGBPJPY;
   
   if(PositionGetString(POSITION_SYMBOL) == "GBPJPY" && isEApVamp)
   if(cProfitGBPJPY == 0)
      {
         MyResult = AccountBalanceInfoGBPJPY;
      }
   
   return MyResult;
   
   }
      
   //+------------------------------------------------------------------+
   //| Money Management Handlers GBPUSD                                 |
   //+------------------------------------------------------------------+
 
 void CheckSellTrailingSlGBPUSD (double GBPUSDBid, double Equity, double AutoTrailGBPUSD, double AtrGBPUSD)
   {
                
      double SL = NormalizeDouble(GBPUSDBid + 2*AtrGBPUSD, DigitsUSD);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("GBPUSD" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(Equity >= AutoTrailGBPUSD)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*PointUSD), NULL);
          }   
        }  
      }   
   }
   
   
   int CountPositionsPerEA_GBPUSD()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("GBPUSD" == CurrencyPair && isEApVamp)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }
   
   
   double CurrentProfitGBPUSD()
   {
   
   double currentProfit = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
     
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0)
        {               
         if(PositionGetString(POSITION_SYMBOL) == "GBPUSD" && isEApVamp)
           {
            currentProfit += PositionGetDouble(POSITION_PROFIT);
           }
        }
     }
   return currentProfit;
   }   
   
   double AccountBalanceGBPUSD()
   {
      uint TotalNumberOfDeals = HistoryDealsTotal();
      ulong TicketNumber = 0;      
      double OrderProfit = 0;
      double Commission = 0;
      double Swap = 0;     
      string MySymbol = "";     
      double MyResult = AccountBalance;
      double BalanceGBPUSD = AccountBalance;     
      
      HistorySelect(0, TimeCurrent());
      for(uint i=0; i < TotalNumberOfDeals; i++)
         {
            if((TicketNumber = HistoryDealGetTicket(i)) > 0)
            {
               OrderProfit = HistoryDealGetDouble(TicketNumber,DEAL_PROFIT);              
               MySymbol = HistoryDealGetString(TicketNumber,DEAL_SYMBOL);
               Commission = HistoryDealGetDouble(TicketNumber,DEAL_COMMISSION);
               Swap = HistoryDealGetDouble(TicketNumber,DEAL_SWAP);
               
               if (MySymbol == "GBPUSD" && isEApVamp && OrderProfit != 0)              
               {
  
                  MyResult = BalanceGBPUSD + OrderProfit + Commission + Swap;
                  BalanceGBPUSD = MyResult;
               
               }
            }
         }
      return MyResult;
   }       

   double AccountEquityGBPUSD(double AccountBalanceInfoGBPUSD, double cProfitGBPUSD)
   {
   
   double MyResult = AccountBalanceInfoGBPUSD + cProfitGBPUSD;
   
   if(PositionGetString(POSITION_SYMBOL) == "GBPUSD" && isEApVamp)
   if(cProfitGBPUSD == 0)
      {
         MyResult = AccountBalanceInfoGBPUSD;
      }
   
   return MyResult;
   
   } 