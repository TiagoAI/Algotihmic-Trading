input double LotSize = 0.1;
input int ema_period = 200;
input int rsi_period = 15;
input double RiskBenefit = 2;

#include <trade/trade.mqh>
CTrade trade;
ulong trade_ticket = 0;
bool time_passed = true;
double entry_price;

int EMA;
int RSI;
double EMA_Array[];
double RSI_Array[];
MqlRates velas[];

bool cond_buy() {
    return velas[1].close > velas[1].open && 
           velas[0].close < velas[0].open && 
           velas[0].open < velas[1].close && 
           velas[0].close > velas[1].open &&
           RSI_Array[0] < 50;
}

bool cond_sell() {
    return velas[1].close < velas[1].open && 
           velas[0].close > velas[0].open && 
           velas[0].open > velas[1].close && 
           velas[0].close < velas[1].open &&
           RSI_Array[0] > 50;
}

int OnInit() {
    EMA = iMA(_Symbol, PERIOD_CURRENT, ema_period, 0, MODE_EMA, PRICE_CLOSE);
    RSI = iRSI(_Symbol, PERIOD_CURRENT, rsi_period, PRICE_CLOSE);
    ArraySetAsSeries(EMA_Array, true);
    ArraySetAsSeries(RSI_Array, true);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}

void OnTick() {
    CopyBuffer(EMA, 0, 0, 3, EMA_Array);
    CopyBuffer(RSI, 0, 0, 3, RSI_Array);
    CopyRates(_Symbol, _Period, 0, 3, velas);

    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

    // Verificar si hay una posición abierta pero no hay tickets comerciales
    if (trade_ticket != 0 && PositionsTotal() == 0) {
        trade_ticket = 0;
    }
       
    if (trade_ticket == 0 && time_passed == true) { 
        if (cond_sell()) 
        {
            double sl = Bid + (velas[0].open - Bid) * 2;
            double tp = Bid - ((velas[0].open - Bid) * 2) * RiskBenefit;
            trade_ticket = trade.Sell(LotSize, _Symbol, Bid, sl, tp);
            time_passed = false;     
            EventSetTimer(PeriodSeconds(PERIOD_CURRENT) * 1);
        }
        else if (cond_buy()) 
        {
            double sl = Ask - (Ask - velas[0].open) * 2;
            double tp = Ask + ((Ask - velas[0].open) * 2) * RiskBenefit;
            trade_ticket = trade.Buy(LotSize, _Symbol, Ask, sl, tp);
            time_passed = false;     
            EventSetTimer(PeriodSeconds(PERIOD_CURRENT) * 1);
        }
    }
}

void OnTimer() { 
    time_passed = true; 
}
