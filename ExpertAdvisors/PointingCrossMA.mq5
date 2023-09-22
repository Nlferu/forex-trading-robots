#include <Trade/Trade.mqh>

   CTrade trade;
   
   input int FastMa = 2;
   input int SlowMa = 7;
   
   input double EqPercentSL = 0.01;       // Equity Percentage Sl
   input double EqPercentTP = 0.10;       // Equity Percentage Tp
   
   bool isFaMaUp = false;
   bool isSlMaUp = false;
   
   bool isFaMaDown = false;
   bool isSlMaDown = false;
   
   int barstemp = 0;                     // Bar counter
   
   double Bid = 0;
   double Ask = 0;   
   
   // Settings - 8 Sl, 36 Tp || 1 Sl 10 Tp 
   
   void OnTick()
   {
      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);   
      
      double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      double EquityStop = (1 - EqPercentSL)*Balance;
      double EquityProfit = (1 + EqPercentTP)*Balance;
      
      start();
   }
  
   void start()
   {
    if(barstemp != Bars(_Symbol, _Period))
    {
         barstemp = Bars(_Symbol, _Period);  
         
   //+------------------------------------------------------------------+
   //| Prices                                                           |
   //+------------------------------------------------------------------+
   
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double LotSize = NormalizeDouble((Balance/10000), 2);
   
   string signal = "";
   
   MqlRates PriceInfo[];
   ArraySetAsSeries (PriceInfo, true);
   int Data = CopyRates (Symbol(), Period(), 0, (SlowMa+3), PriceInfo);
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss                                             |
   //+------------------------------------------------------------------+
   
   double EquityStop = (1 - EqPercentSL)*Balance;
   double EquityProfit = (1 + EqPercentTP)*Balance;
   
   //+------------------------------------------------------------------+
   //| Moving Averages                                                  |
   //+------------------------------------------------------------------+
   
   int FastMA = iMA(_Symbol, _Period, FastMa, 3, MODE_SMA, PRICE_HIGH);
   
   double MovingAverage[];
   ArraySetAsSeries(MovingAverage, true);
   CopyBuffer(FastMA, 0, -1, (FastMa+3), MovingAverage);
   double FaMa = MovingAverage[0];
   double FaMa1 = MovingAverage[1];
   double FaMa2 = MovingAverage[2];
   double FaMa3 = MovingAverage[3];
   
   int SlowMA = iMA(_Symbol, _Period, SlowMa, 3, MODE_EMA, FastMA);
   
   double MovingAverage2[];
   ArraySetAsSeries(MovingAverage2, true);
   CopyBuffer(SlowMA, 0, -1, (SlowMa+3), MovingAverage2);
   double SlMa = MovingAverage2[0];
   double SlMa1 = MovingAverage2[1];
   double SlMa2 = MovingAverage2[2];
   double SlMa3 = MovingAverage2[3];
   
   //+------------------------------------------------------------------+
   //| Signals                                                          |
   //+------------------------------------------------------------------+
   
   if(!isFaMaUp)
      if(FaMa3 < FaMa2 && FaMa2 < FaMa1)
         {
            isFaMaUp = true;
         }
   if(isFaMaUp)
      if(FaMa2 > FaMa1)
         {
            isFaMaUp = false;
         }
   if(!isFaMaDown)
      if(FaMa3 > FaMa2 && FaMa2 > FaMa1)
         {
            isFaMaDown = true;
         }
   if(isFaMaDown)
      if(FaMa2 < FaMa1)
         {
            isFaMaDown = false;
         }  
         
   if(!isSlMaUp)
   if(SlMa3 < SlMa2 && SlMa2 < SlMa1)
      {
         isSlMaUp = true;
      }
   if(isSlMaUp)
      if(SlMa2 > SlMa1)
         {
            isSlMaUp = false;
         }
   if(!isSlMaDown)
      if(SlMa3 > SlMa2 && SlMa2 > SlMa1)
         {
            isSlMaDown = true;
         }
   if(isSlMaDown)
      if(SlMa2 < SlMa1)
         {
            isSlMaDown = false;
         } 
   
   if(isFaMaUp && isSlMaUp && Bid > FaMa && FaMa1 > SlMa1)
      {
         signal = "buy";
      }
   
   if(isFaMaDown && isSlMaDown && Bid < FaMa && FaMa1 < SlMa1)
      {
         signal = "sell";
      } 
   
   //+------------------------------------------------------------------+
   //| Trades                                                           |
   //+------------------------------------------------------------------+
   
   if(signal == "buy" && PositionsTotal() < 30)
     {
        trade.Buy(LotSize, _Symbol, Ask, NULL, NULL, NULL);
     }
        
   if(signal == "sell" && PositionsTotal() < 30)
     {
        trade.Sell(LotSize, _Symbol, Bid, NULL, NULL, NULL);
     }
     
   BuyMoneyManagement(Equity, EquityStop, EquityProfit, PriceInfo, FaMa1, SlMa1);
   SellMoneyManagement(Equity, EquityStop, EquityProfit, PriceInfo, FaMa1, SlMa1);
   
   //Comment("\nisFaMaUp ", isFaMaUp, 
   //     "\nisFaMaDown ", isFaMaDown,
   //     "\nisSlMaUp ", isSlMaUp,
   //     "\nisSlMaDown ", isSlMaDown,
   //     "\nFaMa1 ", FaMa1);
    }
   }   
   
   void BuyMoneyManagement(double Equity, double EquityStop, double EquityProfit, MqlRates &PriceInfo[], double FaMa1, double SlMa1)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_BUY)
        {                         
        if(Equity <= EquityStop || isFaMaDown && isSlMaDown && Bid < FaMa1 && Bid < SlMa1) // || (PriceInfo[1].close < FaMa1 && PriceInfo[1].close < SlMa1)
          {
           trade.PositionClose(ticket);
          }           

        if(Equity >= EquityProfit)
          {
           trade.PositionClose(ticket);
          }
        }     
      }   
   }
   
   void SellMoneyManagement(double Equity, double EquityStop, double EquityProfit, MqlRates &PriceInfo[], double FaMa1, double SlMa1)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_SELL)
        {                          
        if(Equity <= EquityStop || isFaMaUp && isSlMaUp && Bid > FaMa1 && Bid > SlMa1) // || (PriceInfo[1].close > FaMa1 && PriceInfo[1].close > SlMa1)
          {
           trade.PositionClose(ticket);
          }           

        if(Equity >= EquityProfit)
          {
           trade.PositionClose(ticket);
          }
        }     
      }   
   }
   
         