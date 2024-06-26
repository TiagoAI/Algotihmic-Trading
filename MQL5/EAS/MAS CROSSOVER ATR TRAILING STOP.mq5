//+------------------------------------------------------------------+
//|                                                   MyExpert.mq5 |
//|                        Copyright 2024, Tiago                     |
//|                                       https://www.mql5.com      |
//+------------------------------------------------------------------+
#property copyright "Tiago"
#property link      "https://www.mql5.com"
#property version   "1.01"

// Include
#include <trade/trade.mqh>
CTrade trade;
ulong trade_ticket;
double open_trade_price = 0;

// Inputs
input double LotSize = 0.1;
input int EMA1Period = 20;
input int EMA2Period = 50;
input int ATRPeriod = 10;
input double ATRFactor = 2.0;

// Handlers
int EMA1;
int EMA2;
int ATR;

// Handlers Arrays
double EMA1Array[];
double EMA2Array[];
double ATRArray[];

// Stops and Values
double ATRValue;

/* =============================================================================== */
bool EMAS_buy() { return EMA1Array[1] < EMA2Array[1] && EMA1Array[0] > EMA2Array[0]; } 
bool EMAS_sell() { return EMA1Array[1] > EMA2Array[1] && EMA1Array[0] < EMA2Array[0]; } 
/* =============================================================================== */


int OnInit()
{ 
    // Validate input parameters
    if (LotSize <= 0 || EMA1Period <= 0 || EMA2Period <= 0 || ATRPeriod <= 0) 
    {
        return INIT_FAILED;
    }
    
    ATRValue = 0;
    
    // Set Handlers
    EMA1 = iMA(_Symbol,_Period,EMA1Period,0,MODE_EMA,PRICE_CLOSE);
    EMA2 = iMA(_Symbol,_Period,EMA2Period,0,MODE_EMA,PRICE_CLOSE);
    ATR = iATR(_Symbol,_Period,ATRPeriod);
    
    // Set Arrays
    ArraySetAsSeries(EMA1Array, true);
    ArraySetAsSeries(EMA2Array, true);
    ArraySetAsSeries(ATRArray, true);
    
    return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason)
{

}

void OnTick()
{     
    // Fill Arrays
    CopyBuffer(EMA1, 0, 0, 2, EMA1Array);
    CopyBuffer(EMA2, 0, 0, 2, EMA2Array);
    CopyBuffer(ATR, 0, 0, 2, ATRArray);
    
    // Get ATR Value
    ATRValue = ATRArray[1] * ATRFactor;

    //Get ASK and BID Prices
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
    
    /* Checking if there's an open operation */
    if (PositionsTotal() == 0 && trade_ticket != 0) { // No operations
      // Reseting the trade flags
      trade_ticket = 0;
    } 

    // Stop Logic
    if (trade_ticket != 0 && PositionsTotal() != 0)
    {
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      ATRValue = ATRArray[1] * ATRFactor;
      double cur_price;
      if (type == POSITION_TYPE_BUY)
        cur_price = Ask;
      else
        cur_price = Bid;

      // Trailing stop logic
      if (type == POSITION_TYPE_BUY && cur_price > open_trade_price + ATRValue) {
        double new_sl = NormalizeDouble(cur_price - ATRValue, _Digits);
        trade.PositionModify(trade_ticket, new_sl, NULL);
        open_trade_price = cur_price; // Update open trade price before next check
      } else if (type == POSITION_TYPE_SELL && cur_price < open_trade_price - ATRValue) {
        double new_sl = NormalizeDouble(cur_price + ATRValue, _Digits);
        trade.PositionModify(trade_ticket, new_sl, NULL);
        open_trade_price = cur_price; // Update open trade price before next check
      }
   }

    // Trade Logic
    if (EMAS_buy() && trade_ticket <= 0)
    {
        double SL = Ask - ATRValue;
        open_trade_price = Ask;
        trade.Buy(LotSize, _Symbol, Ask, SL);
        trade_ticket = trade.ResultOrder();
    }
    
    // Sell Condition
    else if (EMAS_sell() && trade_ticket <= 0)
    {
        double SL = Bid + ATRValue;  
        open_trade_price = Bid;
        trade.Sell(LotSize, _Symbol, Bid, SL);  
        trade_ticket = trade.ResultOrder();
    }            
}
