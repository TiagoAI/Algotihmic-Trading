#property copyright "Tiago"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Include
#include <trade/trade.mqh>
CTrade trade;

// Inputs
input double LotSize = 0.5;
input int TP_PIPS = 60;
input int SL_PIPS = 30;
input int RsiPeriod = 15;
input int RsiHighLevel = 70;
input int RsiLowLevel = 30;
input int NumberOfEmas = 0;
input int Ema1Period = 10;
input int Ema2Period = 50;
input ulong InpMagic = 4567;

// Handlers
int EMA1;
int EMA2;
int RSI;

// Handlers Arrays
double EMA1Array[];
double EMA2Array[];
double RsiArray[];

/* =============================================================================== */
bool EMAS_buy() { return EMA1Array[0] < EMA2Array[0]; } 
bool EMAS_sell() { return EMA1Array[0] > EMA2Array[0]; } 

bool RSI_buy() { return RsiArray[1] >= RsiLowLevel && RsiArray[0] < RsiLowLevel; }
bool RSI_sell() { return RsiArray[1] <= RsiHighLevel && RsiArray[0] > RsiHighLevel; }
/* =============================================================================== */


int OnInit()
{
    // Set magic number for the expert advisor
    trade.SetExpertMagicNumber(InpMagic);
    
    // Validate input parameters
    if (LotSize <= 0)
    {
        Print("Invalid lot size. Please provide a valid lot size.");
        return INIT_FAILED;
    }
    
    EMA1 = iMA(_Symbol,_Period, Ema1Period, 0, MODE_EMA, PRICE_CLOSE);
    EMA2 = iMA(_Symbol,_Period, Ema2Period, 0, MODE_EMA, PRICE_CLOSE);
    RSI = iRSI(_Symbol,_Period,RsiPeriod,PRICE_CLOSE);
    
    // Additional checks for input parameters
    if (RsiPeriod <= 0 || RsiHighLevel <= 0 || RsiLowLevel >= 100 
        || Ema1Period <= 0 || Ema2Period <= 0) 
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
    // Check for existing positions
    if (PositionsTotal() > 0)
    {
        return; // Exit if there are open positions
    }

    // Fill Arrays
   ArraySetAsSeries(RsiArray, true);
   CopyBuffer(RSI, 0, 0, 2, RsiArray);

   if (NumberOfEmas >= 1) {
      ArraySetAsSeries(EMA1Array, true);
      CopyBuffer(EMA1, 0, 0, 2, EMA1Array);
   }

   if (NumberOfEmas >= 2) {
      ArraySetAsSeries(EMA2Array, true);
      CopyBuffer(EMA2, 0, 0, 2, EMA2Array);
   }

    
    //Get ASK and BID Prices
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

    // Trade Logic: NO EMA´s
    if (NumberOfEmas == 0)
    {
       // Buy Condition
       if (RSI_buy())
       {
          double SL = Ask - SL_PIPS * 10 * _Point;  
          double TP = Ask + TP_PIPS * 10 * _Point; 
          trade.Buy(LotSize, _Symbol, Ask, SL, TP);
       }
    
       // Sell Condition
       else if (RSI_sell())
       {
          double SL = Bid + SL_PIPS * 10 * _Point;  
          double TP = Bid - TP_PIPS * 10 * _Point; 
          trade.Sell(LotSize, _Symbol, Bid, SL, TP);  
       }
    }
    
    // Trade Logic: 1 EMA
    else if (NumberOfEmas == 1)
    {
       // Buy Condition
       if (RSI_buy() && Ask < EMA1Array[0])
       {
          double SL = Ask - SL_PIPS * 10 * _Point;  
          double TP = Ask + TP_PIPS * 10 * _Point; 
          trade.Buy(LotSize, _Symbol, Ask, SL, TP);
       }
    
       // Sell Condition
       else if (RSI_sell() && Bid > EMA1Array[0])
       {
          double SL = Bid + SL_PIPS * 10 * _Point;  
          double TP = Bid - TP_PIPS * 10 * _Point; 
          trade.Sell(LotSize, _Symbol, Bid, SL, TP);  
       }
    }
    
    // Trade Logic: 2 EMA´s
    else if (NumberOfEmas == 2)
    {
       // Buy Condition
       if (RSI_buy() && EMAS_buy())
       {
          double SL = Ask - SL_PIPS * 10 * _Point;  
          double TP = Ask + TP_PIPS * 10 * _Point; 
          trade.Buy(LotSize, _Symbol, Ask, SL, TP);
       }
    
       // Sell Condition
       else if (RSI_sell() && EMAS_sell())
       {
          double SL = Bid + SL_PIPS * 10 * _Point;  
          double TP = Bid - TP_PIPS * 10 * _Point; 
          trade.Sell(LotSize, _Symbol, Bid, SL, TP);  
       }
    }
}
