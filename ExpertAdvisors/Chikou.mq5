   #include <Trade/Trade.mqh>

   CTrade trade;

   bool isSellCross = false;
   bool isBuyCross = false;
   double tp = 0;
   double sl = 0;
   
   //+------------------------------------------------------------------+
   //| Money Management po Equity                                       |
   //+------------------------------------------------------------------+
   
   input double FixedStop = 40;           // StopLoss is 30/1000 -> 3% sl +10 spread = 40
   input double AtrScope = 1000;          // It says how many candles ATR indi should check
   input double CurrencyCorrector = 100;  // Depends on how many digits currency have -> for 3 digits it is 100 -> for 5 digits it is 10000 so -> """ (digits - 1) = amount of "0" after 1 """
   
   input double MyStopLossValue = 1.5;    // StopLoss up to 2
   input double MyTakeProfitValue = 10;   // TakeProfit up to 2
   input double MySecondProfit = 1.5;     // MM ATR up to 3
   input int MySSSValue = 24;             // Kijun and SSB to 30
   input int MySSBValue = 66;             // SSB Value
   input double MyAtrValue = 100;         // ATR up to 100
   input double KsRange = 0;              // Ks Range
   input double SsbRange = 400;           // Ssb Range
   input double EqPercentSL = 0.03;       // Equity Percentage Sl 23 for euraud 2014
   input double EqPercentTP = 5;          // Equity Percentage Tp 0.0275
   input double SsbTpCorrection = 41;     // SSB Slippage from Tp
   
   input double EqPercentTr = 0.03;       // Equity Percentage Trailing Sl
   input double TrailSlVal = 3000;        // It is GAP between current price and SL

void OnTick()
{

   //+------------------------------------------------------------------+
   //| Prices                                                           |
   //+------------------------------------------------------------------+
   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   //double LotSize = NormalizeDouble((Equity/15151.52), 2);
   
   string signal = "";
  
   MqlRates PriceInfo[];
   ArraySetAsSeries (PriceInfo, true);
   int Data = CopyRates (Symbol(), Period(), 0, (MySSBValue+3), PriceInfo);
   
   //+------------------------------------------------------------------+
   //| ATR                                                              |
   //+------------------------------------------------------------------+
   
   double ATRValue[];                   
   int ATRHandle = iATR(_Symbol, 0, 1000); 
   ArraySetAsSeries( ATRValue, true );
   if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
      {
    
      }
   double ATR = ATRValue[0];
   
   double Interval = ATR*CurrencyCorrector;
   
   // Error Handler
   
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
      
     double stop = Bid + ((Interval + sl)*_Point);
     double take = Bid - ((Interval + tp)*_Point);
     
     double stop2 = Bid - ((Interval + sl)*_Point);
     double take2 = Bid + ((Interval + tp)*_Point);
     
     double AutoSL = (1 - EqPercentSL)*Balance;
     double AutoTP = (1 + EqPercentTP)*Balance;
     
     double AutoTrail = (1 + EqPercentTr)*Balance;   
     double TrailSellSL = stop;          //Abstract SL first lvl
     double TrailBuySL = stop2;

//   double sl = (Bid + 1.5*ATR);
//   double tp = (Ask - 1.5*ATR);
//   
//   double slB = (Ask - 1.5*ATR);
//   double tpB = (Bid + 1.5*ATR);
   
   //+------------------------------------------------------------------+
   //| Ichimoku                                                         |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinition = iIchimoku(_Symbol, _Period, MySSSValue, MySSSValue, MySSBValue);
   
   double KijunArray[];
   ArraySetAsSeries(KijunArray, true);
   CopyBuffer(IchimokuDefinition, 1, 0, (MySSSValue+3), KijunArray);
   double KijunValue = KijunArray[MySSSValue];
   double KijunValueS = KijunArray[MySSSValue+1];
   double KijunValueSs = KijunArray[(MySSSValue+2)];
   
   double SSBArray[];
   ArraySetAsSeries(SSBArray, true);
   CopyBuffer(IchimokuDefinition, 3, 0, (MySSSValue+3), SSBArray);
   double SSBValue0 = SSBArray[0];
   double SSBValue = SSBArray[MySSSValue];
   double SSBValueS = SSBArray[MySSSValue+1];
   double SSBValueSs = SSBArray[(MySSSValue+2)];
   
   double ChikouArray[];
   ArraySetAsSeries(ChikouArray, true);
   CopyBuffer(IchimokuDefinition, 4, 0, (MySSSValue+3), ChikouArray);
   double ChikouValue = ChikouArray[MySSSValue+1];
   double ChikouValueS = ChikouArray[(MySSSValue+2)];
   
   //+------------------------------------------------------------------+
   //| Sell                                                             |
   //+------------------------------------------------------------------+
    
   if(!isSellCross)
      if(ChikouValueS > KijunValueSs)
         if(ChikouValue < KijunValueS)
         {
            isSellCross = true;
         }
   
     
   if(isSellCross)
      if(ChikouValueS < KijunValueSs)
         if(ChikouValue > KijunValueS)
         {
            isSellCross = false;
         }         
   
   if(isSellCross)         
      if(PriceInfo[1].close < KijunArray[1] && PriceInfo[1].close > SSBArray[1])
         if(PriceInfo[1].close < KijunValueS)
            if(Bid > SSBArray[0] && Bid < KijunArray[0])
               if(Bid - SSBArray[0] > SsbRange*_Point)   
                  if(PriceInfo[1].close < PriceInfo[MySSSValue].low)
                     {
                        isSellCross = false;
                        signal = "sell";
                     }
     
   //+------------------------------------------------------------------+
   //| Buy                                                              |
   //+------------------------------------------------------------------+ 
   
   if(!isBuyCross)
      if(ChikouValueS < KijunValueSs)
         if(ChikouValue > KijunValueS)
         {
            isBuyCross = true;
         }
   
   if(isBuyCross)
      if(ChikouValueS > KijunValueSs)
         if(ChikouValue < KijunValueS)
         {
            isBuyCross = false;
         }      
   
   if(isBuyCross)         
      if(PriceInfo[1].close > KijunArray[1] && PriceInfo[1].close < SSBArray[1])
         if(PriceInfo[1].close > KijunValueS)
            if(Ask < SSBArray[0] && Ask > KijunArray[0])   
               if(SSBArray[0] - Ask > SsbRange*_Point)
                  if(PriceInfo[1].close > PriceInfo[MySSSValue].high)
                     {
                        isBuyCross = false;
                        signal = "buy";
                     }
     
   //+------------------------------------------------------------------+
   //| Trades                                                           |
   //+------------------------------------------------------------------+
  
   
   if(signal == "sell" && PositionsTotal() < 1)
   {
      trade.Sell(LotSize, _Symbol, Bid, TrailSellSL, NULL, NULL);
   }   
      
   //CloseSellPosition(Bid, KijunValue, SSBValue0, PriceInfo, LotSize, Balance, Equity, AutoSL, AutoTP);
   CheckSellTrailingSl (Bid, Equity, AutoTrail);
   
   if(signal == "buy" && PositionsTotal() < 1)
   {
      trade.Buy(LotSize, _Symbol, Ask, TrailBuySL, NULL, NULL);
   } 
   
   //CloseBuyPosition(Ask, KijunValue, SSBValue0, PriceInfo, LotSize, Balance, Equity, AutoSL, AutoTP);
   CheckBuyTrailingSl (Ask, Equity, AutoTrail);  
   
   //Comment("\nThe current signal is: ", signal,
   //        "\nChikou 28: ", ChikouValue,
   //        "\nChikou 29: ", ChikouValueS,
   //        "\nKijun 28: ", KijunValueShif,
   //        "\nKijun 29: ", KijunValueShifS,
   //        "\nKijun 0: ", KijunValue);
   //Comment ("\nEquity : ", ATR,
   //         "\nLotSize : ", Interval,
   //         "\nAutoSL : ", AutoSL);

}

   //+------------------------------------------------------------------+
   //| Money Management Handler                                         |
   //+------------------------------------------------------------------+

void CheckSellBreakEvenStop(double Bid, double ATR)
   {   
                    
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double PositionSellPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double PositionStopLoss = PositionGetDouble(POSITION_SL);
         double PositionTakeProfit = PositionGetDouble(POSITION_TP);
         double PositionType = PositionGetInteger(POSITION_TYPE);
         
         string symbol = PositionGetSymbol(i);
         
      if(_Symbol == symbol)
      if(PositionType == POSITION_TYPE_SELL)
      if(PositionStopLoss > PositionSellPrice)
      if(Bid < (PositionSellPrice - ATR))
         {
            trade.PositionModify(PositionTicket, PositionSellPrice - 4*_Point, (Bid - 1.5*ATR));
            trade.PositionClosePartial(PositionTicket, 0.33, NULL);
         }   
      }   
   }
   
   void CheckBuyBreakEvenStop(double Ask, double ATR)
   {   

      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double PositionStopLoss = PositionGetDouble(POSITION_SL);
         double PositionTakeProfit = PositionGetDouble(POSITION_TP);
         double PositionType = PositionGetInteger(POSITION_TYPE);
         
         string symbol = PositionGetSymbol(i);
         
      if(_Symbol == symbol)
      if(PositionType == POSITION_TYPE_BUY)
      if(PositionStopLoss < PositionBuyPrice)
      if(Ask > (PositionBuyPrice + ATR))
         {
            trade.PositionModify(PositionTicket, PositionBuyPrice + 4*_Point, (Ask + 1.5*ATR));
            trade.PositionClosePartial(PositionTicket, 0.33, NULL);
         }   
      }   
   }
   
   void CloseSellPosition(double Bid, double KijunValue, double SSBValue0, MqlRates &PriceInfo[], double LotSize, double Balance, double Equity, double AutoSL, double AutoTP)
   {    
         
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double PositionSellPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double PositionStopLoss = PositionGetDouble(POSITION_SL);
         double PositionTakeProfit = PositionGetDouble(POSITION_TP);
         double PositionType = PositionGetInteger(POSITION_TYPE);
         
         string symbol = PositionGetSymbol(i);
         
      if(_Symbol == symbol)
      if(PositionType == POSITION_TYPE_SELL)
      if(Equity <= AutoSL || Equity >= AutoTP || Bid <= (SSBValue0 + SsbTpCorrection*_Point))
         {
            trade.PositionClose(PositionTicket, NULL);
         }   
      }   
   } 
   
   
 void CloseBuyPosition(double Ask, double KijunValue, double SSBValue0, MqlRates &PriceInfo[], double LotSize, double Balance, double Equity, double AutoSL, double AutoTP)
   {    
      
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double PositionStopLoss = PositionGetDouble(POSITION_SL);
         double PositionTakeProfit = PositionGetDouble(POSITION_TP);
         double PositionType = PositionGetInteger(POSITION_TYPE);
         
         string symbol = PositionGetSymbol(i);
         
      if(_Symbol == symbol)
      if(PositionType == POSITION_TYPE_BUY)
      if(Equity <= AutoSL || Equity >= AutoTP || Ask >= (SSBValue0 - SsbTpCorrection*_Point))
         {
            trade.PositionClose(PositionTicket, NULL);
         }   
      }   
   } 
   
   // || PriceInfo[1].close > (KijunValue + KsRange*_Point) Close position when price pass Ks
   // || PriceInfo[1].close < (KijunValue - KsRange*_Point) Close position when price pass Ks
   
   // Bid <= (SSBValue + SsbTpCorrection*_Point) ||         Close position when price hit Ssb
   // Ask >= (SSBValue - SsbTpCorrection*_Point) ||         Close position when price hit Ssb
   
    void CheckSellTrailingSl (double Bid, double Equity, double AutoTrail)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR(_Symbol, 0, 1000); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
      {
      } 
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Bid + TrailSlVal*_Point, _Digits);                // IS IT GAP?? -> It is
      double SL = NormalizeDouble(Bid + 2*AtrVal, _Digits); // 2 x ATR sl      
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if(_Symbol == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_SELL)
         if(Equity >= AutoTrail)
         if(CurrentStopLoss > SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss - 50*_Point), NULL); // o tyle sie przesuwa co tick
          }   
        }  
      }   
   }
   
    void CheckBuyTrailingSl (double Ask, double Equity, double AutoTrail)
   {
      
      double ATRValue[];                   
      int ATRHandle = iATR(_Symbol, 0, 1000); 
      ArraySetAsSeries(ATRValue, true);
      if(CopyBuffer(ATRHandle, 0, 0, 5, ATRValue) > 0)
      {
      } 
      double AtrVal = ATRValue[0];
      
      //double SL = NormalizeDouble(Ask - TrailSlVal*_Point, _Digits);
      double SL = NormalizeDouble(Ask - 2*AtrVal, _Digits);
      
      for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        string symbol = PositionGetSymbol(i);
        
        if(_Symbol == symbol)
        {
         int PositionDirection = PositionGetInteger(POSITION_TYPE);
         ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
         double CurrentStopLoss = PositionGetDouble(POSITION_SL);
         if(PositionDirection == POSITION_TYPE_BUY)
         if(Equity >= AutoTrail)
         if(CurrentStopLoss < SL)
          {
           trade.PositionModify(PositionTicket, (CurrentStopLoss + 50*_Point), NULL); // O tyle sie przesuwa co tick
          }   
        }  
      }   
   }         