#property copyright "Tiago"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Include
#include <trade/trade.mqh>
CTrade trade;
ulong trade_ticket;

// Inputs
input double LotSize = 0.1;
input int TP_PIPS = 60;
input int SL_PIPS = 30;
input int RsiPeriod = 15;
input int BBPeriod = 20;
input int BBDev = 2;

// Handlers
int BB;
int RSI;

// Handlers Arrays
double BBArrayUp[];
double BBArrayDw[];
double RsiArray[];
MqlRates velas[];

/* =============================================================================== */
bool BB_buy() { return velas[0].close < BBArrayDw[0]; } 
bool BB_sell() { return velas[0].close > BBArrayUp[0]; } 

bool RSI_buy() { return RsiArray[1] >= 30 && RsiArray[0] < 30; }
bool RSI_sell() { return RsiArray[1] <= 70 && RsiArray[0] > 70; }
/* =============================================================================== */

// Función para comprobar si hay una operación abierta
bool operacion_cerrada() {
   return !PositionSelectByTicket(trade_ticket);
}

// Función para comprobar si estamos en una nueva vela
int bars;
bool nueva_vela() {
   int current_bars = Bars(_Symbol, _Period);
   if (current_bars != bars) {
      bars = current_bars;
      return true;
   }
   
   return false;
}


int OnInit()
{ 
    // Validate input parameters
    if (LotSize <= 0)
    {
        return INIT_FAILED;
    }
    
    // Set Handlers
    BB = iBands(_Symbol,_Period,BBPeriod,0,BBDev,PRICE_CLOSE);
    RSI = iRSI(_Symbol,_Period,RsiPeriod,PRICE_CLOSE);
    
    // Set Arrays
    ArraySetAsSeries(RsiArray, true);
    ArraySetAsSeries(BBArrayUp, true);
    ArraySetAsSeries(BBArrayDw, true);
    
    // Additional checks for input parameters
    if (RsiPeriod <= 0 || BBPeriod <= 0) 
    {
        return INIT_FAILED;
    }
    
    return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason)
{
   // Add any cleanup code if necessary
}

void OnTick()
{     
    // Fill Arrays
    CopyBuffer(RSI, 0, 0, 2, RsiArray);
    CopyBuffer(BB, UPPER_BAND, 0, 2, BBArrayUp);
    CopyBuffer(BB, LOWER_BAND, 0, 2, BBArrayDw);
    CopyRates(_Symbol, _Period, 0, 1, velas);

    //Get ASK and BID Prices
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

    // Trade Logic
    if (RSI_buy() && BB_buy() && nueva_vela() && operacion_cerrada())
       {
          double SL = Ask - SL_PIPS * 10 * _Point;  
          double TP = Ask + TP_PIPS * 10 * _Point; 
          trade.Buy(LotSize, _Symbol, Ask, SL, TP);
       }
    
       // Sell Condition
       else if (RSI_sell() && BB_sell() && nueva_vela() && operacion_cerrada())
       {
          double SL = Bid + SL_PIPS * 10 * _Point;  
          double TP = Bid - TP_PIPS * 10 * _Point; 
          trade.Sell(LotSize, _Symbol, Bid, SL, TP);  
       }
}
