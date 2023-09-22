   #include <Trade/Trade.mqh>

   CTrade trade;
   
   bool isCrossUp = false;
   bool isCrossDown = false;
   
   input int FastMa = 20;
   input int SlowMa = 200;              
   
   input double LotDivider = 8000;        // 1000 = 10 Lots, 10000 = 1 Lot
   input double EqPercentSL = 0.05;       // Equity Percentage Sl
   input double EqPercentTP = 0.01;       // Equity Percentage Tp
   
   // SL = 30 pips
   // SMA = 20
   // SMA = 200 na M5
   // SMA 20 przecina SMA 200 od dolu to buy
   
void OnTick()
  {
   //+------------------------------------------------------------------+
   //| Prices                                                           |
   //+------------------------------------------------------------------+
   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double LotSize = NormalizeDouble((Balance/LotDivider), 2);
   if(LotSize >= 100)
      {
         LotSize = 100;
      }
   
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
   
   int FastMA = iMA(_Symbol, _Period, FastMa, 0, MODE_SMA, PRICE_CLOSE);
   
   double MovingAverage[];
   ArraySetAsSeries(MovingAverage, true);
   CopyBuffer(FastMA, 0, 0, (FastMa+3), MovingAverage);
   double FaMa1 = MovingAverage[1];
   double FaMa2 = MovingAverage[2];
   
   int SlowMA = iMA(_Symbol, _Period, SlowMa, 0, MODE_SMA, PRICE_CLOSE);
   
   double MovingAverage2[];
   ArraySetAsSeries(MovingAverage2, true);
   CopyBuffer(SlowMA, 0, 0, (SlowMa+3), MovingAverage2);
   double SlMa1 = MovingAverage2[1];
   double SlMa2 = MovingAverage2[2];
   
   //+------------------------------------------------------------------+
   //| Buy                                                              |
   //+------------------------------------------------------------------+
   
   if(!isCrossUp)
      if(FaMa2 < SlMa2 && FaMa1 > SlMa1)
         {
           isCrossUp = true;
        }
         
   if(isCrossUp)
      if(FaMa2 > SlMa2 && FaMa1 < SlMa1)
        {
           isCrossUp = false;
        }
         
   if(isCrossUp)
      {
         isCrossUp = false;
         signal = "buy";
      }           
   
   //+------------------------------------------------------------------+
   //| Sell                                                             |
   //+------------------------------------------------------------------+
   
   if(!isCrossDown)
      if(FaMa2 > SlMa2 && FaMa1 < SlMa1)
           {
              isCrossDown = true;
           }
           
   if(isCrossDown)
      if(FaMa2 < SlMa2 && FaMa1 > SlMa1)
         {
            isCrossDown = false;
         }               

   if(isCrossDown)
      {        
         isCrossDown = false;
         signal = "sell";
      }    
   
   //+------------------------------------------------------------------+
   //| Trades                                                           |
   //+------------------------------------------------------------------+  
   
     if(signal == "buy" && PositionsTotal() < 1)
     {      
        trade.Buy(LotSize, _Symbol, Ask, (Bid - 300*_Point), (Bid + 600*_Point), NULL);
     }             
     
     if(signal == "sell" && PositionsTotal() < 1)
     {       
        trade.Sell(LotSize, _Symbol, Bid, (Ask + 300*_Point), (Ask - 600*_Point), NULL);       
     }
     
     //BuyMoneyManagement(Equity, EquityStop, EquityProfit);
     //SellMoneyManagement(Equity, EquityStop, EquityProfit); 
   
   //+------------------------------------------------------------------+
   //| Comments                                                         |
   //+------------------------------------------------------------------+ 
   
   //Comment("\nMa0: ", FaMa1,
   //        "\nMa1: ", SlMa1,            
   //        "\nsignal: ", signal);           
   
   } 
   
   void BuyMoneyManagement(double Equity, double EquityStop, double EquityProfit)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_BUY)
        {                 
        if(isCrossDown) // If there is opposite signal close trade
          {
           isCrossUp = false;
           trade.PositionClose(ticket); 
          }

        if(Equity <= EquityStop)  
          {                   
           isCrossUp = false;
           trade.PositionClose(ticket);
          }           

        if(Equity >= EquityProfit)
          {
           isCrossUp = false;
           trade.PositionClose(ticket);
          }
        }     
      }   
   }
   
   void SellMoneyManagement(double Equity, double EquityStop, double EquityProfit)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionSellPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_SELL)
        {                 
        if(isCrossUp) // If there is opposite signal close trade
          {
           isCrossDown = false;
           trade.PositionClose(ticket); 
          }
        
        if(Equity <= EquityStop)
          {
           isCrossDown = false;
           trade.PositionClose(ticket);
          }           
        
        if(Equity >= EquityProfit)
          {
           isCrossDown = false;
           trade.PositionClose(ticket);
          }
        }      
      }   
   }         