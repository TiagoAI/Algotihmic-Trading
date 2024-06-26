
#define FIBO_OBJ "Fibo Retracement"

#include <trade/trade.mqh>
CTrade trade;

// Grouping of input parameters for lot size
input group "LotSize";
input double RiskAmount = 100;   // Fixed risk amount in account currency
input double RiskPercentage = 0.2;   // Risk percentage of account balance

// Grouping of input parameters for Fibonacci levels
input group "Fibonacci";
input int FiboLevelOpen = 70;           // Fibonacci level for entry point
input int FiboLevelProfit = 10;         // Fibonacci level for take-profit
input int FiboLevelStop = 100;          // Fibonacci level for stop-loss

double EntryLevel, StopLossLevel, TakeProfitLevel;
int barsTotal;

// Function to calculate lot size
double CalculateLotSize(double entry, double stopLoss)
{
    // Calculate stop loss distance in points
    double stopLossPoints = MathAbs(entry - stopLoss) / _Point;

    // Get account balance
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    // Calculate risk amount in account currency if RiskAmount is 0
    double riskAmount = RiskAmount;
    if (RiskAmount <= 0) {
        riskAmount = (accountBalance * RiskPercentage) / 100.0;
    }

    // Get tick value
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

    // Get leverage
    long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);

    // Calculate lot size
    double lotSize = (riskAmount / stopLossPoints) / (tickValue * leverage);

    return NormalizeDouble(lotSize, 2); // Normalize lot size to 2 decimals
}

// OnInit function
int OnInit()
{

   OnTick();
   return INIT_SUCCEEDED;
}

// OnDeinit function
void OnDeinit(const int reason)
{
    // Close any open position before deinitialization
    if(PositionsTotal() > 0)
    {
        trade.PositionClose(_Symbol);
        Print("Open position closed before deinitialization.");
    }
}

// OnTick function
void OnTick()
{
    int bars = iBars(_Symbol,PERIOD_D1);
    if(barsTotal != bars)
    {
        barsTotal = bars;
        ObjectDelete(0,FIBO_OBJ);
        
        double open = iOpen(_Symbol,PERIOD_D1,1);
        double close = iClose(_Symbol,PERIOD_D1,1);
        
        double high = iHigh(_Symbol,PERIOD_D1,1);
        double low = iLow(_Symbol,PERIOD_D1,1);
        
        datetime timeStart = iTime(_Symbol,PERIOD_D1,1);
        datetime timeEnd = iTime(_Symbol,PERIOD_D1,0)-1;
        datetime expiration = iTime(_Symbol,PERIOD_D1,0) + PeriodSeconds(PERIOD_D1);
        
        // If close is greater than open, create Fibonacci object and set trade parameters
        if(close > open){
           ObjectCreate(0,FIBO_OBJ,OBJ_FIBO,0,timeStart,low,timeEnd,high);
           EntryLevel = NormalizeDouble(high - (high - low) * FiboLevelOpen / 100, _Digits);
           StopLossLevel = NormalizeDouble(high - (high - low) * FiboLevelStop / 100, _Digits);
           TakeProfitLevel = NormalizeDouble(high - (high - low) * FiboLevelProfit / 100, _Digits);
           double lotSize = CalculateLotSize(EntryLevel,StopLossLevel);
           if(lotSize <= 0)
           {
               Print("Invalid lot size calculated.");
               return;
           }
           if(!trade.BuyLimit(lotSize,EntryLevel,_Symbol,StopLossLevel,TakeProfitLevel,ORDER_TIME_SPECIFIED,expiration))
           {
               Print("Failed to place buy limit order. Error code: ", GetLastError());
           }
        }
        // If close is less than open, create Fibonacci object and set trade parameters
        else{
           ObjectCreate(0,FIBO_OBJ,OBJ_FIBO,0,timeStart,high,timeEnd,low);    
           EntryLevel = NormalizeDouble(low + (high - low) * FiboLevelOpen / 100, _Digits);
           StopLossLevel = NormalizeDouble(low + (high - low) * FiboLevelStop / 100, _Digits);
           TakeProfitLevel = NormalizeDouble(low + (high - low) * FiboLevelProfit / 100, _Digits);
           double lotSize = CalculateLotSize(EntryLevel,StopLossLevel);    
           if(lotSize <= 0)
           {
               Print("Invalid lot size calculated.");
               return;
           }
           if(!trade.SellLimit(lotSize,EntryLevel,_Symbol,StopLossLevel,TakeProfitLevel,ORDER_TIME_SPECIFIED,expiration))
           {
               Print("Failed to place sell limit order. Error code: ", GetLastError());
           }
        }
        // Set Fibonacci object color
        ObjectGetInteger(0,FIBO_OBJ,OBJPROP_COLOR,clrYellow);
        for(int i = 0; i < ObjectGetInteger(0,FIBO_OBJ,OBJPROP_LEVELS);i++){
           ObjectSetInteger(0,FIBO_OBJ,OBJPROP_LEVELCOLOR,i,clrYellow);
        }
    }
}