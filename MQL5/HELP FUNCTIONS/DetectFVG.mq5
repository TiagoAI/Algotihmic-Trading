struct FVG {
   double high;
   double low;
   double candle_high;
   double candle_low;
   datetime start_time;
   datetime end_time;
};

class FVGs {
   private:
      void reset();
      void add(FVG &fvg);

   public:
      FVG fvgs[];
      
      bool is(int index, MqlRates &velas[]);
      short get(datetime _start, datetime _end, string _symbol, ENUM_TIMEFRAMES _period);
      void draw(color clr, int length=10);
};

void FVGs::reset() {
   ArrayResize(this.fvgs, 0);
}

void FVGs::add(FVG &fvg) {
   // El FVG más reciente está al final del array!!
   int size = ArraySize(this.fvgs);
   ArrayResize(this.fvgs, size+1);
   this.fvgs[size] = fvg;
}

bool FVGs::is(int index, MqlRates &velas[]) {
   return velas[index].low > velas[index+2].high || velas[index].high < velas[index+2].low;   
}

short FVGs::get(datetime _start, datetime _end, string _symbol, ENUM_TIMEFRAMES _period) {
   // Cargamos las velas
   MqlRates velas[];
   ArraySetAsSeries(velas, true);
   CopyRates(_symbol, _period, _start, _end, velas);
   
   short num_fvgs = 0;
   int num_velas = ArraySize(velas);
   
   this.reset();
   
   // Iteramos sobre las velas
   for (int i = 0; i < num_velas-2; i++) {
      // Buscamos FVG
      if (this.is(i, velas)) {
         FVG fvg;
         bool low_above_high = velas[i].low > velas[i+2].high;

         fvg.candle_high = low_above_high ? velas[i].high : velas[i+2].high;
         fvg.candle_low = low_above_high ? velas[i+2].low : velas[i].low;
         fvg.high = low_above_high ? velas[i].low : velas[i+2].low;
         fvg.low = low_above_high ? velas[i+2].high : velas[i].high;
         fvg.start_time = velas[i+2].time;
         fvg.end_time = velas[i].time;
         
         this.add(fvg);

         num_fvgs++;
      }
   }
   
   return num_fvgs++;
}
void FVGs::draw(color clr, int length=10) {
   for (int i = 0; i < ArraySize(this.fvgs); i++) {
      FVG fvg = this.fvgs[i];
      string name = "fvg"+IntegerToString(fvg.start_time);
      ObjectCreate(
         0, 
         name,
         OBJ_RECTANGLE,
         0,
         fvg.start_time,
         fvg.high,
         fvg.start_time+length*PeriodSeconds(),
         fvg.low
      );
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }
}
