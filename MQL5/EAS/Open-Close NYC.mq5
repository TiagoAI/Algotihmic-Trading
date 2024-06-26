
// Inputs
input double LotSize = 0.1;
input int period_ma = 50;

#include <Trade/Trade.mqh>
CTrade   trade;
ulong    trade_ticket = 0;

// KillZones Hours
string HOUROPENNY   = "15:30";
string HOURCLOSENY   = "20:00";

int MA;
double MA_Array[];

MqlRates velas[];

int OnInit()
  {
   MA = iMA(_Symbol, _Period, period_ma, 0, MODE_EMA, PRICE_CLOSE);
   ArraySetAsSeries(MA_Array, true);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
     CopyRates(_Symbol, _Period, 0, 3, velas);
     
     // Time Filter
     datetime timeStart = StringToTime(HOUROPENNY);
     datetime timeEnd = StringToTime(HOURCLOSENY);
     
     double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
     CopyBuffer(MA, 0, 1, 2, MA_Array);
     
     // Buy the close
     if (TimeCurrent() == timeEnd && trade_ticket == 0  && velas[1].close < velas[1].open)
     {
         trade_ticket = trade.Buy(LotSize);
     }
          
     // Sell the next open
     if (trade_ticket != 0 && TimeCurrent() == timeStart)
     {
        trade.PositionClose(_Symbol);
        trade_ticket = 0;
     }

}