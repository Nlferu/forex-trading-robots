#property library

#include <Trade/Trade.mqh>

   CTrade trade;
   
   input double FixedStop = 40;                 // StopLoss is 30/1000 -> 3% sl +10 spread = 40
   input double CurrencyCorrectorJPY = 100;     // Depends on how many digits currency have -> for 3 digits it is 100 -> for 5 digits it is 10000 so -> """ (digits - 1) = amount of "0" after 1 """
   input double CurrencyCorrectorUSD = 10000;
  
   input int MySSSValueUSDJPY = 13;                   // Value of Kijun and SSB 16 is best
   input int MySSSValueGBPJPYs = 11;
   input int MySSSValueGBPJPYb = 24;
   input int MySSSValueGBPUSD = 7;
  
   input double AtrScope = 1000;                // ATR up to 100
   input double EqPercentTr = 0.03;             // Equity Percentage Trailing Sl
   input double TrailSlVal = 3000;              // It is GAP between current price and SL
   
   bool isEAKsSSB = true;

   // *** KijunSSBH4 *** \\
   
   // - USDJPY - Buy
   // - GBPJPY - Buy and Sell
   // - GBPUSD - Sell
   
void KijunSSBH4() export
  {

  //+------------------------------------------------------------------+
  //| Prices                                                           |
  //+------------------------------------------------------------------+   

   double USDJPYBid = NormalizeDouble(SymbolInfoDouble("USDJPY", SYMBOL_BID), _Digits);
   double USDJPYAsk = NormalizeDouble(SymbolInfoDouble("USDJPY", SYMBOL_ASK), _Digits);
   
   double GBPJPYBid = NormalizeDouble(SymbolInfoDouble("GBPJPY", SYMBOL_BID), _Digits);
   double GBPJPYAsk = NormalizeDouble(SymbolInfoDouble("GBPJPY", SYMBOL_ASK), _Digits);
   
   double GBPUSDBid = NormalizeDouble(SymbolInfoDouble("GBPUSD", SYMBOL_BID), _Digits);
   double GBPUSDAsk = NormalizeDouble(SymbolInfoDouble("GBPUSD", SYMBOL_ASK), _Digits);
   
   double Balance = 1000;                                                              //AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
   string signal = "";
   
   MqlRates PriceInformationUSDJPY[];  
   ArraySetAsSeries (PriceInformationUSDJPY, true);
   int DataUSDJPY = CopyRates ("USDJPY", Period(), 0, (MySSSValueUSDJPY + 3), PriceInformationUSDJPY);
   
   MqlRates PriceInformationGBPJPY[];  
   ArraySetAsSeries (PriceInformationGBPJPY, true);
   int DataGBPJPY = CopyRates ("GBPJPY", Period(), 0, (MySSSValueGBPJPYb + 3), PriceInformationGBPJPY); 
   
   MqlRates PriceInformationGBPUSD[];  
   ArraySetAsSeries (PriceInformationGBPUSD, true);
   int DataGBPUSD = CopyRates ("GBPUSD", Period(), 0, (MySSSValueGBPUSD + 3), PriceInformationGBPUSD);    
  
  //+------------------------------------------------------------------+
  //| ATR USDJPY                                                       |
  //+------------------------------------------------------------------+
   
   double ATRValueUSDJPY[];                   
   int ATRHandleUSDJPY = iATR("USDJPY", 0, AtrScope); 
   ArraySetAsSeries( ATRValueUSDJPY, true );
   if(CopyBuffer(ATRHandleUSDJPY, 0, 0, 5, ATRValueUSDJPY) > 0)
      {
    
      }
   double AtrUSDJPY = ATRValueUSDJPY[0];
   
   double IntervalUSDJPY = AtrUSDJPY*CurrencyCorrectorJPY;
   
   // ** Error Handler **
   
   if(IntervalUSDJPY == 0)
   {
      IntervalUSDJPY = 30;
   }

  //+------------------------------------------------------------------+
  //| ATR GBPJPY                                                       |
  //+------------------------------------------------------------------+
   
   double ATRValueGBPJPY[];                   
   int ATRHandleGBPJPY = iATR("GBPJPY", 0, AtrScope); 
   ArraySetAsSeries( ATRValueGBPJPY, true );
   if(CopyBuffer(ATRHandleGBPJPY, 0, 0, 5, ATRValueGBPJPY) > 0)
      {
    
      }
   double AtrGBPJPY = ATRValueGBPJPY[0];
   
   double IntervalGBPJPY = AtrGBPJPY*CurrencyCorrectorJPY;
   
   // ** Error Handler **
   
   if(IntervalGBPJPY == 0)
   {
      IntervalGBPJPY = 30;
   }
   
  //+------------------------------------------------------------------+
  //| ATR GBPUSD                                                       |
  //+------------------------------------------------------------------+
   
   double ATRValueGBPUSD[];                   
   int ATRHandleGBPUSD = iATR("GBPUSD", 0, AtrScope); 
   ArraySetAsSeries( ATRValueGBPUSD, true );
   if(CopyBuffer(ATRHandleGBPUSD, 0, 0, 5, ATRValueGBPUSD) > 0)
      {
    
      }
   double AtrGBPUSD = ATRValueGBPUSD[0];
   
   double IntervalGBPUSD = AtrGBPUSD*CurrencyCorrectorUSD;
   
   // ** Error Handler **
   
   if(IntervalGBPUSD == 0)
   {
      IntervalGBPUSD = 30;
   }
         
  //+------------------------------------------------------------------+
  //| TakeProfit, StopLoss USDJPY                                      |
  //+------------------------------------------------------------------+
   
     double xUSDJPY = FixedStop/(IntervalUSDJPY*10);
     double LotSizeUSDJPY = NormalizeDouble(xUSDJPY, 2);
     
     double USDJPYsl= (IntervalUSDJPY + 1)*10;
     double USDJPYtp = (IntervalUSDJPY + 2)*10;  
      
     double USDJPYstopS = USDJPYBid + ((IntervalUSDJPY + USDJPYsl)*_Point);
     double USDJPYtakeS = USDJPYBid - ((IntervalUSDJPY + USDJPYtp)*_Point);
     
     double USDJPYstopB = USDJPYBid - ((IntervalUSDJPY + USDJPYsl)*_Point);
     double USDJPYtakeB = USDJPYBid + ((IntervalUSDJPY + USDJPYtp)*_Point);
     
     double AutoTrailUSDJPY = (1 + EqPercentTr)*Balance;   
     double USDJPYTrailSellSL = USDJPYstopS;                          
     double USDJPYTrailBuySL = USDJPYstopB; 

  //+------------------------------------------------------------------+
  //| TakeProfit, StopLoss GBPJPY                                      |
  //+------------------------------------------------------------------+
   
     double xGBPJPY = FixedStop/(IntervalGBPJPY*10);
     double LotSizeGBPJPY = NormalizeDouble(xGBPJPY, 2);
     
     double GBPJPYsl= (IntervalGBPJPY + 1)*10;
     double GBPJPYtp = (IntervalGBPJPY + 2)*10;  
      
     double GBPJPYstopS = GBPJPYBid + ((IntervalGBPJPY + GBPJPYsl)*_Point);
     double GBPJPYtakeS = GBPJPYBid - ((IntervalGBPJPY + GBPJPYtp)*_Point);
     
     double GBPJPYstopB = GBPJPYBid - ((IntervalGBPJPY + GBPJPYsl)*_Point);
     double GBPJPYtakeB = GBPJPYBid + ((IntervalGBPJPY + GBPJPYtp)*_Point);
     
     double AutoTrailGBPJPY = (1 + EqPercentTr)*Balance;   
     double GBPJPYTrailSellSL = GBPJPYstopS;                          
     double GBPJPYTrailBuySL = GBPJPYstopB; 

  //+------------------------------------------------------------------+
  //| TakeProfit, StopLoss GBPUSD                                      |
  //+------------------------------------------------------------------+
   
     double xGBPUSD = FixedStop/(IntervalGBPUSD*10);
     double LotSizeGBPUSD = NormalizeDouble(xGBPUSD, 2);
     
     double GBPUSDsl= (IntervalGBPUSD + 1)*10;
     double GBPUSDtp = (IntervalGBPUSD + 2)*10;  
      
     double GBPUSDstopS = GBPUSDBid + ((IntervalGBPUSD + GBPUSDsl)*_Point);
     double GBPUSDtakeS = GBPUSDBid - ((IntervalGBPUSD + GBPUSDtp)*_Point);
     
     double GBPUSDstopB = GBPUSDBid - ((IntervalGBPUSD + GBPUSDsl)*_Point);
     double GBPUSDtakeB = GBPUSDBid + ((IntervalGBPUSD + GBPUSDtp)*_Point);
     
     double AutoTrailGBPUSD = (1 + EqPercentTr)*Balance;   
     double GBPUSDTrailSellSL = GBPUSDstopS;                          
     double GBPUSDTrailBuySL = GBPUSDstopB; 
             
  //+------------------------------------------------------------------+
  //| Ichimoku USDJPY                                                  |
  //+------------------------------------------------------------------+  
       
   int IchimokuDefinitionUSDJPY = iIchimoku("USDJPY", _Period, MySSSValueUSDJPY, MySSSValueUSDJPY, MySSSValueUSDJPY);
   
   double KijunArrayUSDJPY[];
   ArraySetAsSeries(KijunArrayUSDJPY, true);
   CopyBuffer(IchimokuDefinitionUSDJPY, 1, 0, (MySSSValueUSDJPY+3), KijunArrayUSDJPY);
   double KijunValueUSDJPY = KijunArrayUSDJPY[0];
   double KijunValueSUSDJPY = KijunArrayUSDJPY[1];
   double KijunValueS2USDJPY = KijunArrayUSDJPY[2];
   double KijunValueSsUSDJPY = KijunArrayUSDJPY[(MySSSValueUSDJPY+1)];
   
   double SSBArrayUSDJPY[];
   ArraySetAsSeries(SSBArrayUSDJPY, true);
   CopyBuffer(IchimokuDefinitionUSDJPY, 3, 0, (MySSSValueUSDJPY+3), SSBArrayUSDJPY);
   double SSBValueUSDJPY = SSBArrayUSDJPY[0];
   double SSBValueSUSDJPY = SSBArrayUSDJPY[1];
   double SSBValueS2USDJPY = SSBArrayUSDJPY[2];
   double SSBValueSsUSDJPY = SSBArrayUSDJPY[MySSSValueUSDJPY];
   
   double ChikouArrayUSDJPY[];
   ArraySetAsSeries(ChikouArrayUSDJPY, true);
   CopyBuffer(IchimokuDefinitionUSDJPY, 4, 0, (MySSSValueUSDJPY+3), ChikouArrayUSDJPY);
   double ChikouValueSUSDJPY = ChikouArrayUSDJPY[MySSSValueUSDJPY];
   double ChikouValueSsUSDJPY = ChikouArrayUSDJPY[(MySSSValueUSDJPY+1)];

  //+------------------------------------------------------------------+
  //| Ichimoku GBPJPY                                                  |
  //+------------------------------------------------------------------+  
   
   //                        *** GBPJPY Sell ***                        \\
       
   int IchimokuDefinitionGBPJPYs = iIchimoku("GBPJPY", _Period, MySSSValueGBPJPYs, MySSSValueGBPJPYs, MySSSValueGBPJPYs);
   
   double KijunArrayGBPJPYs[];
   ArraySetAsSeries(KijunArrayGBPJPYs, true);
   CopyBuffer(IchimokuDefinitionGBPJPYs, 1, 0, (MySSSValueGBPJPYs+3), KijunArrayGBPJPYs);
   double KijunValueGBPJPYs = KijunArrayGBPJPYs[0];
   double KijunValueSGBPJPYs = KijunArrayGBPJPYs[1];
   double KijunValueS2GBPJPYs = KijunArrayGBPJPYs[2];
   double KijunValueSsGBPJPYs = KijunArrayGBPJPYs[(MySSSValueGBPJPYs+1)];
   
   double SSBArrayGBPJPYs[];
   ArraySetAsSeries(SSBArrayGBPJPYs, true);
   CopyBuffer(IchimokuDefinitionGBPJPYs, 3, 0, (MySSSValueGBPJPYs+3), SSBArrayGBPJPYs);
   double SSBValueGBPJPYs = SSBArrayGBPJPYs[0];
   double SSBValueSGBPJPYs = SSBArrayGBPJPYs[1];
   double SSBValueS2GBPJPYs = SSBArrayGBPJPYs[2];
   double SSBValueSsGBPJPYs = SSBArrayGBPJPYs[MySSSValueGBPJPYs];
   
   double ChikouArrayGBPJPYs[];
   ArraySetAsSeries(ChikouArrayGBPJPYs, true);
   CopyBuffer(IchimokuDefinitionGBPJPYs, 4, 0, (MySSSValueGBPJPYs+3), ChikouArrayGBPJPYs);
   double ChikouValueSGBPJPYs = ChikouArrayGBPJPYs[MySSSValueGBPJPYs];
   double ChikouValueSsGBPJPYs = ChikouArrayGBPJPYs[(MySSSValueGBPJPYs+1)];
   
   //                        *** GBPJPY Buy ***                        \\
   
   int IchimokuDefinitionGBPJPYb = iIchimoku("GBPJPY", _Period, MySSSValueGBPJPYb, MySSSValueGBPJPYb, MySSSValueGBPJPYb);
   
   double KijunArrayGBPJPYb[];
   ArraySetAsSeries(KijunArrayGBPJPYb, true);
   CopyBuffer(IchimokuDefinitionGBPJPYb, 1, 0, (MySSSValueGBPJPYb+3), KijunArrayGBPJPYb);
   double KijunValueGBPJPYb = KijunArrayGBPJPYb[0];
   double KijunValueSGBPJPYb = KijunArrayGBPJPYb[1];
   double KijunValueS2GBPJPYb = KijunArrayGBPJPYb[2];
   double KijunValueSsGBPJPYb = KijunArrayGBPJPYb[(MySSSValueGBPJPYb+1)];
   
   double SSBArrayGBPJPYb[];
   ArraySetAsSeries(SSBArrayGBPJPYb, true);
   CopyBuffer(IchimokuDefinitionGBPJPYb, 3, 0, (MySSSValueGBPJPYb+3), SSBArrayGBPJPYb);
   double SSBValueGBPJPYb = SSBArrayGBPJPYb[0];
   double SSBValueSGBPJPYb = SSBArrayGBPJPYb[1];
   double SSBValueS2GBPJPYb = SSBArrayGBPJPYb[2];
   double SSBValueSsGBPJPYb = SSBArrayGBPJPYb[MySSSValueGBPJPYb];
   
   double ChikouArrayGBPJPYb[];
   ArraySetAsSeries(ChikouArrayGBPJPYb, true);
   CopyBuffer(IchimokuDefinitionGBPJPYb, 4, 0, (MySSSValueGBPJPYb+3), ChikouArrayGBPJPYb);
   double ChikouValueSGBPJPYb = ChikouArrayGBPJPYb[MySSSValueGBPJPYb];
   double ChikouValueSsGBPJPYb = ChikouArrayGBPJPYb[(MySSSValueGBPJPYb+1)];
   
  //+------------------------------------------------------------------+
  //| Ichimoku GBPUSD                                                  |
  //+------------------------------------------------------------------+  
       
   int IchimokuDefinitionGBPUSD = iIchimoku("GBPUSD", _Period, MySSSValueGBPUSD, MySSSValueGBPUSD, MySSSValueGBPUSD);
   
   double KijunArrayGBPUSD[];
   ArraySetAsSeries(KijunArrayGBPUSD, true);
   CopyBuffer(IchimokuDefinitionGBPUSD, 1, 0, (MySSSValueGBPUSD+3), KijunArrayGBPUSD);
   double KijunValueGBPUSD = KijunArrayGBPUSD[0];
   double KijunValueSGBPUSD = KijunArrayGBPUSD[1];
   double KijunValueS2GBPUSD = KijunArrayGBPUSD[2];
   double KijunValueSsGBPUSD = KijunArrayGBPUSD[(MySSSValueGBPUSD+1)];
   
   double SSBArrayGBPUSD[];
   ArraySetAsSeries(SSBArrayGBPUSD, true);
   CopyBuffer(IchimokuDefinitionGBPUSD, 3, 0, (MySSSValueGBPUSD+3), SSBArrayGBPUSD);
   double SSBValueGBPUSD = SSBArrayGBPUSD[0];
   double SSBValueSGBPUSD = SSBArrayGBPUSD[1];
   double SSBValueS2GBPUSD = SSBArrayGBPUSD[2];
   double SSBValueSsGBPUSD = SSBArrayGBPUSD[MySSSValueGBPUSD];
   
   double ChikouArrayGBPUSD[];
   ArraySetAsSeries(ChikouArrayGBPUSD, true);
   CopyBuffer(IchimokuDefinitionGBPUSD, 4, 0, (MySSSValueGBPUSD+3), ChikouArrayGBPUSD);
   double ChikouValueSGBPUSD = ChikouArrayGBPUSD[MySSSValueGBPUSD];
   double ChikouValueSsGBPUSD = ChikouArrayGBPUSD[(MySSSValueGBPUSD+1)];      
            
  //+------------------------------------------------------------------+
  //| Buy Signal USDJPY                                                |
  //+------------------------------------------------------------------+
  
   //if(KijunValueS > SSBValueS)  //with cross
     if(PriceInformationUSDJPY[1].close > KijunValueSUSDJPY && PriceInformationUSDJPY[1].close > SSBValueSUSDJPY)                //PriceInformation[2].close < SSBValueS2 && 
         if(PriceInformationUSDJPY[1].close > PriceInformationUSDJPY[MySSSValueUSDJPY].high)
            if(USDJPYAsk > KijunValueUSDJPY)
              if((USDJPYAsk - KijunValueUSDJPY) < 3*AtrUSDJPY || (USDJPYAsk - SSBValueUSDJPY) < 3*AtrUSDJPY)        
                 {
                   signal = "USDJPYbuy";     
                 } 

  //+------------------------------------------------------------------+
  //| Sell Signal GBPJPY                                               |
  //+------------------------------------------------------------------+
       
   //if(KijunValueS < SSBValueS)  //with cross
     if(PriceInformationGBPJPY[1].close < KijunValueSGBPJPYs && PriceInformationGBPJPY[1].close < SSBValueSGBPJPYs)
         if(PriceInformationGBPJPY[1].close < PriceInformationGBPJPY[MySSSValueGBPJPYs].low)
            if(GBPJPYBid < KijunValueGBPJPYs) 
               if((KijunValueGBPJPYs - GBPJPYBid) < 3*AtrGBPJPY || (SSBValueGBPJPYs - GBPJPYBid) < 3*AtrGBPJPY)      
                 {
                   signal = "GBPJPYsell";     
                 }    
            
  //+------------------------------------------------------------------+
  //| Buy Signal GBPJPY                                                |
  //+------------------------------------------------------------------+
  
   //if(KijunValueS > SSBValueS)  //with cross
     if(PriceInformationGBPJPY[1].close > KijunValueSGBPJPYb && PriceInformationGBPJPY[1].close > SSBValueSGBPJPYb)                //PriceInformation[2].close < SSBValueS2 && 
         if(PriceInformationGBPJPY[1].close > PriceInformationGBPJPY[MySSSValueGBPJPYb].high)
            if(GBPJPYAsk > KijunValueGBPJPYb)
              if((GBPJPYAsk - KijunValueGBPJPYb) < 3*AtrGBPJPY || (GBPJPYAsk - SSBValueGBPJPYb) < 3*AtrGBPJPY)        
                 {
                   signal = "GBPJPYbuy";     
                 } 

  //+------------------------------------------------------------------+
  //| Sell Signal GBPUSD                                               |
  //+------------------------------------------------------------------+
       
   //if(KijunValueS < SSBValueS)  //with cross
     if(PriceInformationGBPUSD[1].close < KijunValueSGBPUSD && PriceInformationGBPUSD[1].close < SSBValueSGBPUSD)
         if(PriceInformationGBPUSD[1].close < PriceInformationGBPUSD[MySSSValueGBPUSD].low)
            if(GBPUSDBid < KijunValueGBPUSD) 
               if((KijunValueGBPUSD - GBPUSDBid) < 3*AtrGBPUSD || (SSBValueGBPUSD - GBPUSDBid) < 3*AtrGBPUSD)      
                 {
                   signal = "GBPUSDsell";     
                 }               
                                  
  //+------------------------------------------------------------------+
  //| Trades USDJPY                                                    |
  //+------------------------------------------------------------------+
   
   if(signal == "USDJPYbuy" && CountPositionsPerEA_USDJPY() < 1) 
   {
      trade.Buy(LotSizeUSDJPY, "USDJPY", USDJPYAsk, USDJPYTrailBuySL, NULL, NULL);
   } 
    
   CheckBuyTrailingSlUSDJPY (USDJPYAsk, Equity, AutoTrailUSDJPY);

  //+------------------------------------------------------------------+
  //| Trades GBPJPY                                                    |
  //+------------------------------------------------------------------+
   
   if(signal == "GBPJPYsell" && CountPositionsPerEA_GBPJPYs() < 1) 
   {
      trade.Sell(LotSizeGBPJPY, "GBPJPY", GBPJPYBid, GBPJPYTrailSellSL, NULL, NULL);
   }  
   
   CheckSellTrailingSlGBPJPY (GBPJPYBid, Equity, AutoTrailGBPJPY);
   
   if(signal == "GBPJPYbuy" && CountPositionsPerEA_GBPJPYb() < 1) 
   {
      trade.Buy(LotSizeGBPJPY, "GBPJPY", GBPJPYAsk, GBPJPYTrailBuySL, NULL, NULL);
   } 
    
   CheckBuyTrailingSlGBPJPY (GBPJPYAsk, Equity, AutoTrailGBPJPY);
   
  //+------------------------------------------------------------------+
  //| Trades GBPUSD                                                    |
  //+------------------------------------------------------------------+
   
   if(signal == "GBPUSDsell" && CountPositionsPerEA_GBPUSD() < 1) 
   {
      trade.Sell(LotSizeGBPUSD, "GBPUSD", GBPUSDBid, GBPUSDTrailSellSL, NULL, NULL);
   }  
   
   CheckSellTrailingSlGBPUSD (GBPUSDBid, Equity, AutoTrailGBPUSD);
      
  //+------------------------------------------------------------------+
  //| Informations On Charts                                           |
  //+------------------------------------------------------------------+
   
   //Comment("\nATR Value is: ", ATR);                 
   
  }
  
  //+------------------------------------------------------------------+
  //| Money Management Handlers                                         |
  //+------------------------------------------------------------------+
   
    void CheckBuyTrailingSlUSDJPY (double USDJPYAsk, double Equity, double AutoTrailGBPJPY)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR("USDJPY", 0, AtrScope); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
      {
      } 
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Ask - TrailSlVal*_Point, _Digits);
      double SL = NormalizeDouble(USDJPYAsk - 2*AtrVal, _Digits);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("USDJPY" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_BUY)
         if(Equity >= AutoTrailGBPJPY)
         if(CurrentStopLoss < SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss + 50*_Point), NULL); 
          }   
        }  
      }   
   }
   
 void CheckSellTrailingSlGBPJPY (double GBPJPYBid, double Equity, double AutoTrailGBPUSD)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR("GBPJPY", 0, AtrScope); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
      {
      } 
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Bid + TrailSlVal*_Point, _Digits);                
      double SL = NormalizeDouble(GBPJPYBid + 2*AtrVal, _Digits); // 2 x ATR sl      
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("GBPJPY" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(Equity >= AutoTrailGBPUSD)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*_Point), NULL); 
          }   
        }  
      }   
   }
   
    void CheckBuyTrailingSlGBPJPY (double GBPJPYAsk, double Equity, double AutoTrail)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR("GBPJPY", 0, AtrScope); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
      {
      } 
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Ask - TrailSlVal*_Point, _Digits);
      double SL = NormalizeDouble(GBPJPYAsk - 2*AtrVal, _Digits);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("GBPJPY" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_BUY)
         if(Equity >= AutoTrail)
         if(CurrentStopLoss < SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss + 50*_Point), NULL); 
          }   
        }  
      }   
   } 
   
 void CheckSellTrailingSlGBPUSD (double GBPUSDBid, double Equity, double AutoTrail)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR("GBPUSD", 0, AtrScope); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
      {
      } 
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Bid + TrailSlVal*_Point, _Digits);                
      double SL = NormalizeDouble(GBPUSDBid + 2*AtrVal, _Digits); // 2 x ATR sl      
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("GBPUSD" == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(Equity >= AutoTrail)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*_Point), NULL); 
          }   
        }  
      }   
   }   
   
   int CountPositionsPerEA_USDJPY()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("USDJPY" == CurrencyPair && isEAKsSSB)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }
   
   int CountPositionsPerEA_GBPJPYs()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            string TradeSide = PositionGetInteger(POSITION_TYPE);
            if("GBPJPY" == CurrencyPair && TradeSide == POSITION_TYPE_SELL && isEAKsSSB)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }
   
   int CountPositionsPerEA_GBPJPYb()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            string TradeSide = PositionGetInteger(POSITION_TYPE);
            if("GBPJPY" == CurrencyPair && TradeSide == POSITION_TYPE_BUY && isEAKsSSB)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }     
   
   int CountPositionsPerEA_GBPUSD()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("GBPUSD" == CurrencyPair && isEAKsSSB)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }                     
