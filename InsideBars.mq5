#include <Trade/Trade.mqh>

   CTrade trade;
   
   input int MyTSSValue = 7;              // Tenkan Value
   input int MySSSValue = 28;             // Kijun Value
   input int MySSBValue = 119;            // SSB Value
   
   input double EqPercentSL = 0.09;       // Equity Percentage Sl
   input double EqPercentTP = 0.13;       // Equity Percentage Tp
   input double Distance = 5;
   
   bool PriceInUpKumo = false;
   bool PriceInDownKumo = false;
   bool PriceInInsideBar = false;
   bool isPriceNear = false;
   
   double InsideBarHigh = 0;
   double InsideBarLow = 0;
   double InsideBarMid = 0;
   
void OnTick()
  {
   
   //+------------------------------------------------------------------+
   //| Prices                                                           |
   //+------------------------------------------------------------------+
   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double LotSize = NormalizeDouble((Balance/10000), 2);
   
   string signal = "";
   
   MqlRates PriceInfo[];
   ArraySetAsSeries (PriceInfo, true);
   int Data = CopyRates (Symbol(), Period(), 0, (MySSBValue+3), PriceInfo);
   
   //+------------------------------------------------------------------+
   //| TakeProfit, StopLoss                                             |
   //+------------------------------------------------------------------+
   
   double EquityStop = (1 - EqPercentSL)*Balance;
   double EquityProfit = (1 + EqPercentTP)*Balance;
   
   //+------------------------------------------------------------------+
   //| Ichimoku                                                         |
   //+------------------------------------------------------------------+
   
   int IchimokuDefinition = iIchimoku(_Symbol, _Period, MyTSSValue, MySSSValue, MySSBValue); 
   
   double SSBArray[];
   ArraySetAsSeries(SSBArray, true);
   CopyBuffer(IchimokuDefinition, 3, 0, (MySSSValue+3), SSBArray);
   double SSBValue = SSBArray[0];
   double SSBValueS = SSBArray[1];
   double SSBValueSs = SSBArray[MySSSValue];
   
   double SSAArray[];
   ArraySetAsSeries(SSAArray, true);
   CopyBuffer(IchimokuDefinition, 2, 0, (MySSSValue+3), SSAArray);
   double SSAValue = SSAArray[0];
   double SSAValueS = SSAArray[1];
   double SSAValueSs = SSAArray[MySSSValue];
   
   //+------------------------------------------------------------------+
   //| Signal                                                           |
   //+------------------------------------------------------------------+
   
   if(!PriceInUpKumo)
      if(PriceInfo[1].close <= SSAValue && PriceInfo[1].close >= SSBValue)
         {
            PriceInUpKumo = true;
         }
         
   if(PriceInUpKumo)
      if(PriceInfo[1].close > SSAValue || PriceInfo[1].close < SSBValue)
         {
            PriceInUpKumo = false;
         }
   
   if(!PriceInDownKumo)
   if(PriceInfo[1].close >= SSAValue && PriceInfo[1].close <= SSBValue)
      {
         PriceInDownKumo = true;
      }
         
   if(PriceInDownKumo)
      if(PriceInfo[1].close < SSAValue || PriceInfo[1].close > SSBValue)
         {
            PriceInDownKumo = false;
         }
               
   if(PriceInUpKumo || PriceInDownKumo)
   if(!PriceInInsideBar && PositionsTotal() < 1)
      if((PriceInfo[1].high < PriceInfo[2].high) && (PriceInfo[1].low > PriceInfo[2].low))
      {
         PriceInInsideBar = true;
         InsideBarHigh = PriceInfo[2].high;
         InsideBarLow = PriceInfo[2].low;
         InsideBarMid = (PriceInfo[2].high + PriceInfo[2].low)/2;
      }
   
   double PriceNear = Bid - InsideBarMid;  
   PriceNear = MathAbs(PriceNear);  
   isPriceNear = PriceNear <= Distance*_Point;
   
   if(PriceInUpKumo || PriceInDownKumo)
   if(PriceInInsideBar)
      if(Bid > InsideBarHigh)
      {
         PriceInInsideBar = false;
         signal = "buy";
      }
   
   if(PriceInUpKumo || PriceInDownKumo)
   if(PriceInInsideBar)
      if(Bid < InsideBarLow)
      {
         PriceInInsideBar = false;
         signal = "sell";
      }
   
   //+------------------------------------------------------------------+
   //| Trades                                                           |
   //+------------------------------------------------------------------+
   
   if(signal == "buy" && PositionsTotal() < 1)
     {
        trade.Buy(LotSize, _Symbol, Ask, NULL, NULL, NULL);
     }
      
   if(signal == "sell" && PositionsTotal() < 1)
     {
        trade.Sell(LotSize, _Symbol, Bid, NULL, NULL, NULL);
     } 
     
   //+------------------------------------------------------------------+
   //| Management                                                       |
   //+------------------------------------------------------------------+
   
   BuyMoneyManagement(Equity, EquityStop, EquityProfit, LotSize, Ask);
   SellMoneyManagement(Equity, EquityStop, EquityProfit, LotSize, Bid);
   
   //Comment("\nPriceInInsideBar ", PriceInInsideBar, 
   //        "\nPriceInUpKumo ", PriceInUpKumo,
   //        "\nPriceInDownKumo ", PriceInDownKumo,
   //        "\nisPriceNear ", isPriceNear,
   //        "\nInsideMid ", InsideBarMid,
   //        "\nEquityStop ", EquityStop);
      
   }
   
   void BuyMoneyManagement(double Equity, double EquityStop, double EquityProfit, double LotSize, double Ask)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_BUY)
        {                 
        if(isPriceNear && PositionsTotal() == 1)
         {
          PriceInInsideBar = false;
          trade.Buy(LotSize, _Symbol, Ask, NULL, NULL, NULL);
         } 
        
        if(Equity <= EquityStop) //|| (Ask <= (InsideBarLow - 100*_Point)))
          {
           PriceInInsideBar = false;
           trade.PositionClose(ticket);
          }           

        if(Equity >= EquityProfit)
          {
           PriceInInsideBar = false;
           trade.PositionClose(ticket);
          }
        }     
      }   
   }
   
   void SellMoneyManagement(double Equity, double EquityStop, double EquityProfit, double LotSize, double Bid)
   {    
      
     for(int i = PositionsTotal() - 1; i>=0; i--)
      {
        int ticket = PositionGetTicket(i);
        int PositionDirection = PositionGetInteger(POSITION_TYPE);
        double PositionBuyPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(PositionDirection == POSITION_TYPE_SELL)
        {                 
        if(isPriceNear && PositionsTotal() == 1)
         {
          PriceInInsideBar = false;
          trade.Sell(LotSize, _Symbol, Bid, NULL, NULL, NULL);
         } 
          
        if(Equity <= EquityStop) //|| (Bid >= (InsideBarHigh + 100*_Point)))
          {
           PriceInInsideBar = false;
           trade.PositionClose(ticket);
          }           

        if(Equity >= EquityProfit)
          {
           PriceInInsideBar = false;
           trade.PositionClose(ticket);
          }
        }     
      }   
   }
