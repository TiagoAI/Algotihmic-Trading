input double LotSize = 0.1;
input int ema_period = 200;

#include <trade/trade.mqh>
CTrade trade;
ulong trade_ticket = 0;
bool time_passed = true;
double entry_price;

int EMA;
double EMA_Array[];
MqlRates velas[];

bool cond_buy() {
    return velas[1].close > velas[1].open && 
           velas[0].close < velas[0].open && 
           velas[0].open < velas[1].close && 
           velas[0].close >= velas[1].open;
}

bool cond_sell() {
    return velas[1].close < velas[1].open && 
           velas[0].close > velas[0].open && 
           velas[0].open > velas[1].close && 
           velas[0].close <= velas[1].open;
}


int OnInit() {
    EMA = iMA(_Symbol, PERIOD_CURRENT, ema_period, 0, MODE_EMA, PRICE_CLOSE);
    ArraySetAsSeries(EMA_Array, true);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
}

void OnTick() {
    CopyBuffer(EMA, 0, 1, 2, EMA_Array);
    CopyRates(_Symbol, _Period, 0, 3, velas);

    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

    // Verificar si hay una posición abierta pero no hay tickets comerciales
    if (trade_ticket != 0 && PositionsTotal() == 0) {
        trade_ticket = 0;
    }
       
    if (trade_ticket == 0) {
        double sl = velas[0].open; // Establecer el stop loss en el precio de apertura de la vela anterior
        if (cond_sell() && Bid < EMA_Array[0]) {
            trade_ticket = trade.Sell(LotSize, _Symbol, Bid, sl);
            time_passed = false;     
            EventSetTimer(PeriodSeconds(PERIOD_CURRENT) * 1);
        }
        else if (cond_buy() && Ask > EMA_Array[0]) {
            trade_ticket = trade.Buy(LotSize, _Symbol, Ask, sl);
            time_passed = false;     
            EventSetTimer(PeriodSeconds(PERIOD_CURRENT) * 1);
        }
    }
    else if (trade_ticket != 0 && time_passed == true) {     
        long position_type = PositionGetInteger(POSITION_TYPE);
        if ((position_type == POSITION_TYPE_SELL && velas[0].close < velas[1].open) ||
            (position_type == POSITION_TYPE_BUY && velas[0].close > velas[1].open)) {
            trade.PositionClose(_Symbol);
            trade_ticket = 0;  
        }
    }
}

void OnTimer() { 
    time_passed = true; 
}
