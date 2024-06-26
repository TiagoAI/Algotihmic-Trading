#property copyright "Tiago"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Inputs
input double LotSize = 0.1;
input double Stop = 0.5;
input double Risk_Benefit = 2;
input int Cond = 1;

#include <Trade/Trade.mqh>
CTrade   trade;
ulong    trade_ticket = 0;

// KillZones Hours
string HOURAFTERNYC   = "16:00";
string HOURENDNYC   = "21:00";
string HOURAFTERTOK   = "5:00";
string HOURENDTOK   = "10:00";

/* Array for candles */
MqlRates candles[];
int MAX_CANDLES = 18;

/* =============================================================================== */
double last_high() {
   double high = 0;
   for (int i = 2; i < MAX_CANDLES; i++) 
      if (candles[i].high > high) high = candles[i].high;
   return high;
}

double last_min() {
   double min = candles[1].high;
   for (int i = 2; i < MAX_CANDLES; i++) 
      if (candles[i].low < min) min = candles[i].low;
   return min;
}

double highestHigh = 0;
double lowestLow = 0;
/* =============================================================================== */
void trailing_stop() 
{
   if (PositionSelectByTicket(trade_ticket)) {
      double sl_anterior = PositionGetDouble(POSITION_SL);
      double current_price = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      long type = PositionGetInteger(POSITION_TYPE);

      double distance = open_price - sl_anterior;
      double new_sl;

      if (type == POSITION_TYPE_BUY) {
          new_sl = current_price - distance;
      } else {
          new_sl = current_price + distance;
      }

      if (new_sl > sl_anterior) {
          trade.PositionModify(trade_ticket, new_sl, NULL);
    }
  }
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
     // Time Filter
     datetime timeStart = StringToTime(HOURAFTERNYC);
     datetime timeEnd = StringToTime(HOURENDNYC);
     datetime timeStart2 = StringToTime(HOURAFTERTOK);
     datetime timeEnd2 = StringToTime(HOURENDTOK);
     bool isTimeOpen = (TimeCurrent() >= timeStart && TimeCurrent() <= timeEnd) || (TimeCurrent() >= timeStart2 && TimeCurrent() <= timeEnd2);
     
     /* Candles */
     CopyRates(_Symbol, _Period, 1, MAX_CANDLES, candles);
     
     // Update High and Low at 16:00
     if (TimeCurrent() == timeStart || TimeCurrent() == timeStart2 )
     {
        highestHigh = last_high();
        lowestLow = last_min();
     }
     
     // Reset Closed Trades
     if (trade_ticket != 0 && PositionsTotal() == 0)
     {
        trade_ticket = 0;
     }

     trailing_stop();
     
     // Trade Logic
     if (trade_ticket == 0 && isTimeOpen)
     {
        // Prices
        double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
        double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
                
        // Buy Trade
        if(Ask > highestHigh && (Cond == 1 || Cond == 3))
        {
           double SL = Ask - (Ask - lowestLow) * Stop;
           double TP = Ask + (Ask - lowestLow) * Risk_Benefit;
           trade_ticket = trade.Buy(LotSize, _Symbol, Ask, SL, TP);
        }
        
        // Sell Trade
        else if(Bid < lowestLow && (Cond == 2 || Cond == 3))
        {
           double SL = Bid + (highestHigh - Bid) * Stop;
           double TP = Bid - (highestHigh - Bid) * Risk_Benefit;
           trade_ticket = trade.Sell(LotSize, _Symbol, Bid, SL, TP);
        }
     }
   
  }
//+------------------------------------------------------------------+
