#property library

   #include <Trade/Trade.mqh>

   CTrade trade;
   
   //*** D1 Trail ***\\
   
   input double FixedStop = 40;           // StopLoss is 30/1000 -> 3% sl +10 spread = 40
   input double CurrencyCorrector = 100;  // Depends on how many digits currency have -> for 3 digits it is 100 -> for 5 digits it is 10000 so -> """ (digits - 1) = amount of "0" after 1 """
  
   input int MySSSValue = 13;             // Value of Kijun and SSB 16 is best
  
   input double AtrScope = 250;           // ATR up to 100
   input double EqPercentTr = 0.03;       // Equity Percentage Trailing Sl
   input double TrailSlVal = 3000;        // It is GAP between current price and SL
   
   bool isSellSignal = false;
   bool isBuySignal = false;
   
   bool isEAD1Trail = true;
   
   double priceSellSignal = 0;
   double priceBuySignal = 0;   

void D1Trail() export
  {

  //+------------------------------------------------------------------+
  //| Prices                                                           |
  //+------------------------------------------------------------------+   

   double Bid = NormalizeDouble(SymbolInfoDouble("USDJPY", SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble("USDJPY", SYMBOL_ASK), _Digits);
   
   double Balance = 1000;
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
   string signal = "";
   
   MqlRates PriceInformation[];  
   ArraySetAsSeries (PriceInformation, true);
   int Data = CopyRates ("USDJPY", Period(), 0, (MySSSValue + 3), PriceInformation);   
  
  //+------------------------------------------------------------------+
  //| ATR                                                              |
  //+------------------------------------------------------------------+
   
   double ATRValue[];                   
   int ATRHandle = iATR("USDJPY", 0, AtrScope); 
   ArraySetAsSeries( ATRValue, true );
   if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0);

   double ATR = ATRValue[0];
   
   double Interval = ATR*CurrencyCorrector;
   
   // ** Error Handler **
   
   if(Interval == 0)
   {
      Interval = 30;
   }
   
  //+------------------------------------------------------------------+
  //| TakeProfit, StopLoss                                             |
  //+------------------------------------------------------------------+
   
     double x = FixedStop/(Interval*10);
     double LotSize = NormalizeDouble(x, 2);
     
     double sl = (Interval + 1)*10;
     double tp = (Interval + 2)*10;  
      
     double stopS = Bid + ((Interval + sl)*_Point);
     double takeS = Bid - ((Interval + tp)*_Point);
     
     double stopB = Bid - ((Interval + sl)*_Point);
     double takeB = Bid + ((Interval + tp)*_Point);
     
     double AutoTrail = (1 + EqPercentTr)*Balance;   
     double TrailSellSL = stopS;                          
     double TrailBuySL = stopB; 
   
  //+------------------------------------------------------------------+
  //| Ichimoku                                                         |
  //+------------------------------------------------------------------+  
       
   int IchimokuDefinition = iIchimoku("USDJPY", _Period, MySSSValue, MySSSValue, MySSSValue);
   
   double KijunArray[];
   ArraySetAsSeries(KijunArray, true);
   CopyBuffer(IchimokuDefinition, 1, 0, (MySSSValue+3), KijunArray);
   double KijunValue = KijunArray[0];
   double KijunValueS = KijunArray[1];
   double KijunValueS2 = KijunArray[2];
   double KijunValueSs = KijunArray[(MySSSValue+1)];
 
  //+------------------------------------------------------------------+
  //| Sell Signal                                                      |
  //+------------------------------------------------------------------+
       
   if(!isSellSignal)
   if(PriceInformation[2].close > KijunValueS2)
      if(PriceInformation[1].close < KijunValueS)
      {
         isSellSignal = true;
         priceSellSignal = PriceInformation[1].low;      
      }    
 
   if(isSellSignal)
      if(PriceInformation[1].close > KijunValueS)
         {
            isSellSignal = false;
         }
   
   if(isSellSignal)
   if((KijunValueS - priceSellSignal) < 1*ATR)
      if(Bid < priceSellSignal)
      {
         isSellSignal = false;
         signal = "sell";      
      }
            
  //+------------------------------------------------------------------+
  //| Buy Signal                                                       |
  //+------------------------------------------------------------------+
  
   if(!isBuySignal)
   if(PriceInformation[2].close < KijunValueS2)
      if(PriceInformation[1].close > KijunValueS)
      {
         isBuySignal = true;
         priceBuySignal = PriceInformation[1].high;      
      }    
 
   if(isBuySignal)
      if(PriceInformation[1].close < KijunValueS)
         {
            isBuySignal = false;
         }
   
   if(isBuySignal)
   if((priceBuySignal - KijunValueS) < 1*ATR)
      if(Ask > priceBuySignal)
      {
         isBuySignal = false;
         signal = "buy";    
      }

  //+------------------------------------------------------------------+
  //| Trades                                                           |
  //+------------------------------------------------------------------+
   
   if(signal == "sell" && CountPositionsPerEA() < 1) 
   {
      trade.Sell(LotSize, "USDJPY", Bid, TrailSellSL, NULL, NULL);
   }  
   
   CheckSellTrailingSl (Bid, Equity, AutoTrail);
   
//   if(signal == "buy" && PositionsTotal() < 1) 
//   {
//      trade.Buy(LotSize, "USDJPY", Ask, TrailBuySL, NULL, NULL);
//   } 
//    
//   CheckBuyTrailingSl (Ask, Equity, AutoTrail);

  //+------------------------------------------------------------------+
  //| Informations On Charts                                           |
  //+------------------------------------------------------------------+
   
//   Comment("\nThe current signal is: ", signal,
//           
//           "\nisBuySignal: ", ATR,
//           "\nisSellSignal: ", ATRValue[0],
//           "\npriceBuySignal: ", priceBuySignal,
//           "\npriceSellSignal: ", priceSellSignal);
                 
  }
  
  //+------------------------------------------------------------------+
  //| Money Management Handlers                                         |
  //+------------------------------------------------------------------+
  
    void CheckSellTrailingSl (double Bid, double Equity, double AutoTrail)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR("USDJPY", 0, AtrScope); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0);
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Bid + TrailSlVal*_Point, _Digits);                
      double SL = NormalizeDouble(Bid + 2*AtrVal, _Digits); // 2 x ATR sl      
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("USDJPY" == symbol)
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
   
    void CheckBuyTrailingSl (double Ask, double Equity, double AutoTrail)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR("USDJPY", 0, AtrScope); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0);
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Ask - TrailSlVal*_Point, _Digits);
      double SL = NormalizeDouble(Ask - 2*AtrVal, _Digits);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if("USDJPY" == symbol)
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

   int CountPositionsPerEA()
   {
      int NumberOfOpenedPositionsPerEA = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            string CurrencyPair = PositionGetSymbol(i);
            if("USDJPY" == CurrencyPair && isEAD1Trail)
               {
                  NumberOfOpenedPositionsPerEA = NumberOfOpenedPositionsPerEA + 1;
               }
         }
      
      return NumberOfOpenedPositionsPerEA;   
   }  