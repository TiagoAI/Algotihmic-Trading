#property copyright "Tiago"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <trade/trade.mqh>
CTrade trade;
ulong trade_ticket = 0;
bool time_passed = true;
double entry_price = 0;

input double LotSize = 0.1;
input int SMA1Period = 200;
input int SMA2Period = 5;
input int Cond = 3;

// Handlers
int SMA1;
int SMA2;

// Arrays
double SMA1Array[];
double SMA2Array[];
MqlRates velas[];

/* =============================================================================== */
bool Cond_buy() { return velas[3].close < velas[3].open && velas[2].close < velas[2].open && velas[1].close < velas[1].open && SMA1Array[1] > SMA1Array[2]; } 
bool Cond_sell() { return velas[3].close > velas[3].open && velas[2].close > velas[2].open && velas[1].close > velas[1].open && SMA1Array[1] < SMA1Array[2]; } 
/* =============================================================================== */

int bars;
bool nueva_vela() {
   int current_bars = Bars(_Symbol, _Period);
   if (current_bars != bars) {
      bars = current_bars;
      return true;
   }
   
   return false;
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    // Set Handlers
    SMA1 = iMA(_Symbol,PERIOD_CURRENT,SMA1Period,0,MODE_SMA,PRICE_CLOSE);
    SMA2 = iMA(_Symbol,PERIOD_CURRENT,SMA2Period,0,MODE_SMA,PRICE_CLOSE);
    
    // Set Arrays
    ArraySetAsSeries(SMA1Array, true);
    ArraySetAsSeries(SMA2Array, true);

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
    // Fill Arrays
    CopyBuffer(SMA1, 0, 0, 5, SMA1Array);
    CopyBuffer(SMA2, 0, 0, 5, SMA2Array);
    CopyRates(_Symbol, _Period, 0, 5, velas);

    // Get Ask Price
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);
    
    // Trade Logic
    if (Cond_buy() && trade_ticket == 0 && time_passed == true && nueva_vela() && (Cond == 1 || Cond == 3))
       {
          entry_price = Ask;
          trade_ticket = trade.Buy(LotSize, _Symbol, Ask);
          time_passed = false;
      
          EventSetTimer(PeriodSeconds(PERIOD_CURRENT)*5);
       }
    else if (Cond_sell() && trade_ticket == 0 && time_passed == true && nueva_vela() && (Cond == 2 || Cond == 3))
       {
          entry_price = Bid;
          trade_ticket = trade.Sell(LotSize, _Symbol, Bid);
          time_passed = false;
      
          EventSetTimer(PeriodSeconds(PERIOD_CURRENT)*5);
       }
       
   /* Checking if there's an open operation */
   if (trade_ticket != 0)
   {
      /* Checking if we have to close the position */
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      if ((type == POSITION_TYPE_BUY && Ask > SMA2Array[0])
      ||  (type == POSITION_TYPE_SELL && Bid < SMA2Array[0])) {
         trade.PositionClose(_Symbol);
         trade_ticket = 0;
         }
   }
  }
//+------------------------------------------------------------------+
void OnTimer() { time_passed = true; }