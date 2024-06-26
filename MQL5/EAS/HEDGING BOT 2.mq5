//+------------------------------------------------------------------+
//|                      SimultaneousEA.mq5  |
//|            Copyright 2024, Company Name        |
//|                    http://www.company.net   |
//+------------------------------------------------------------------+
#property copyright "Tiago"
#property link "https://www.mql5.com"  // Corrected double quotes for link
#property version "1.00"

// Include standard library for trading operations
#include <trade/trade.mqh>
CTrade trade; // Trade object for executing trade operations

// Input parameters for the EA
input double LotSize = 0.1; // The size of each trade
input int TakeProfitPips = 5; // The profit target in pips
input double Multiplier = 2.0; // The multiplier for hedging iterations (added decimal point for clarity)
input int maxHedgingIterations = 4; // The max of iterations

// Global variables to keep track of trade tickets and entry prices
int ticket_buy = -1; // Ticket number for the buy position
int ticket_sell = -1; // Ticket number for the sell position
double entryPriceAsk; // Entry price for the buy position
double entryPriceBid; // Entry price for the sell position
int hedging = 0; // Hedging counter
bool open = false; // Open position flag
double currentLotSize; // Current lot size for positions
double SLTP; // Take Profit pips in points

// Global variable to keep track of the last trade direction
enum ENUM_TRADE_DIRECTION
  {
   TRADE_BUY,
   TRADE_SELL
  };

ENUM_TRADE_DIRECTION lastTradeType;

//+------------------------------------------------------------------+
//| Expert initialization function                  |
//+------------------------------------------------------------------+
int OnInit() {
  // Initialize EA
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function - called on every new tick         |
//+------------------------------------------------------------------+
void OnTick()
{
   // Restart the loop
   if(hedging == maxHedgingIterations)
   {
      ticket_buy = -1;
      ticket_sell = -1;
      open = false;
      hedging = 0;
      return;
   }

   // Retrieve current ASK and BID prices
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

   // Check if there are no open positions
   if(ticket_buy == -1 && ticket_sell == -1 && open == false && hedging == 0 && PositionsTotal() == 0)
   {
      // Open simultaneous buy and sell positions
      entryPriceAsk = Ask;
      entryPriceBid = Bid;
      currentLotSize = LotSize;
      SLTP = TakeProfitPips * 10 * _Point;
      ticket_buy = trade.Buy(currentLotSize, _Symbol, Ask, Ask - SLTP, Ask + SLTP);
      ticket_sell = trade.Sell(currentLotSize, _Symbol, Bid, Bid + SLTP, Bid - SLTP);
      open = true;
   }
   else if(open == true && PositionsTotal() == 0)
   {
      // Check Pips, Take profit and new order
      if(Ask >= entryPriceAsk + SLTP)
      {
         entryPriceAsk = Ask;
         ticket_buy = trade.Buy(currentLotSize, _Symbol, Ask, Ask - SLTP, Ask + SLTP);
         lastTradeType = TRADE_BUY;
      }
      else if(Bid <= entryPriceBid - SLTP)
      {
         entryPriceBid = Bid;
         ticket_sell = trade.Sell(currentLotSize, _Symbol, Bid, Bid + SLTP, Bid - SLTP);
         lastTradeType = TRADE_SELL;
      }

      // Check for multiplie Lotsize and hedging and new multiplied order
      if((Bid >= entryPriceBid + SLTP && lastTradeType == TRADE_SELL) || (Ask <= entryPriceAsk - SLTP && lastTradeType == TRADE_BUY))
      {
         currentLotSize *= Multiplier;
         hedging++;
         if(lastTradeType == TRADE_SELL)
         {
            entryPriceAsk = Ask;
            ticket_buy = trade.Buy(currentLotSize, _Symbol, Ask, Ask - SLTP, Ask + SLTP);
            lastTradeType = TRADE_BUY;
         }
         else if(lastTradeType == TRADE_BUY)
         {
            entryPriceBid = Bid;
            ticket_sell = trade.Sell(currentLotSize, _Symbol, Bid, Bid + SLTP, Bid - SLTP);
            lastTradeType = TRADE_SELL;
         }
      }
   }
}
//+------------------------------------------------------------------+
