//------------------------------------------------------------------
#property copyright   "© mladen, 2018"
#property link        "mladenfx@gmail.com"
#property description "Heiken ashi smoothed zone trade"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 15
#property indicator_plots   1
#property indicator_label1  "Heiken ashi open;Heiken ashi high;Heiken ashi low;Heiken ashi close";
#property indicator_type1   DRAW_COLOR_CANDLES 
#property indicator_color1  clrDeepSkyBlue,clrSandyBrown,clrSilver,clrSilver
//
//---
//
input int            inpMaPeriod      = 7;         // Smoothing period (<= 1 for no smoothing)
input ENUM_MA_METHOD inpMaMetod       = MODE_LWMA; // Smoothing method
input double         inpStep          = 0;         // Step size (in pips)
input bool           inpBetterFormula = false;     // Use better formula?
//
//---
//
double canh[],canl[],cano[],canc[],cancl[],hah[],hal[],hao[],hac[],haC[],mah[],mal[],mao[],mac[],acb[],aob[];
int _mao,_mac,_mal,_mah,_ach,_aoh;
//------------------------------------------------------------------
//
//------------------------------------------------------------------
int OnInit()
{
   SetIndexBuffer( 0,cano ,INDICATOR_DATA);
   SetIndexBuffer( 1,canh ,INDICATOR_DATA);
   SetIndexBuffer( 2,canl ,INDICATOR_DATA);
   SetIndexBuffer( 3,canc ,INDICATOR_DATA);
   SetIndexBuffer( 4,cancl,INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 5,hao  ,INDICATOR_DATA);
   SetIndexBuffer( 6,hah  ,INDICATOR_DATA);
   SetIndexBuffer( 7,hal  ,INDICATOR_DATA);
   SetIndexBuffer( 8,hac  ,INDICATOR_DATA);
   SetIndexBuffer( 9,mac  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,mao  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,mah  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,mal  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,acb  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,aob  ,INDICATOR_CALCULATIONS);
         int _maPeriod = inpMaPeriod>0 ? inpMaPeriod : 1;
         _mao = iMA(_Symbol,0,_maPeriod,0,inpMaMetod,PRICE_OPEN ); if (!_checkHandle(_mao,"Moving average of open"))  return(INIT_FAILED);
         _mac = iMA(_Symbol,0,_maPeriod,0,inpMaMetod,PRICE_CLOSE); if (!_checkHandle(_mac,"Moving average of close")) return(INIT_FAILED);
         _mah = iMA(_Symbol,0,_maPeriod,0,inpMaMetod,PRICE_HIGH ); if (!_checkHandle(_mah,"Moving average of high"))  return(INIT_FAILED);
         _mal = iMA(_Symbol,0,_maPeriod,0,inpMaMetod,PRICE_LOW  ); if (!_checkHandle(_mal,"Moving average of low"))   return(INIT_FAILED);
         _ach = iAC(_Symbol,0);                                    if (!_checkHandle(_ach,"Accelerator Oscillator"))  return(INIT_FAILED);
         _aoh = iAO(_Symbol,0);                                    if (!_checkHandle(_aoh,"Awesome Oscillator"))      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
//------------------------------------------------------------------
//
//------------------------------------------------------------------
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(BarsCalculated(_mao)<rates_total) return(prev_calculated);
   if(BarsCalculated(_mac)<rates_total) return(prev_calculated);
   if(BarsCalculated(_mah)<rates_total) return(prev_calculated);
   if(BarsCalculated(_mal)<rates_total) return(prev_calculated);
   if(BarsCalculated(_ach)<rates_total) return(prev_calculated);
   if(BarsCalculated(_aoh)<rates_total) return(prev_calculated);
   
   //
   //---
   //
      
      int _copyCount = rates_total-prev_calculated+1; if (_copyCount>rates_total) _copyCount=rates_total;
            if (CopyBuffer(_mao,0,0,_copyCount,mao)!=_copyCount) return(prev_calculated);
            if (CopyBuffer(_mac,0,0,_copyCount,mac)!=_copyCount) return(prev_calculated);
            if (CopyBuffer(_mah,0,0,_copyCount,mah)!=_copyCount) return(prev_calculated);
            if (CopyBuffer(_mal,0,0,_copyCount,mal)!=_copyCount) return(prev_calculated);
            if (CopyBuffer(_ach,0,0,_copyCount,acb)!=_copyCount) return(prev_calculated);
            if (CopyBuffer(_aoh,0,0,_copyCount,aob)!=_copyCount) return(prev_calculated);
      double _step=inpStep>0?inpStep*MathPow(10,_Digits%2)*_Point:0;
   
   //
   //---
   //

   int i=(prev_calculated>0?prev_calculated-1:0); for (; i<rates_total && !_StopFlag; i++)
   {
      double maOpen  = mao[i]!=EMPTY_VALUE ? mao[i] : open[i];
      double maClose = mac[i]!=EMPTY_VALUE ? mac[i] : close[i];
      double maLow   = mal[i]!=EMPTY_VALUE ? mal[i] : low[i];
      double maHigh  = mah[i]!=EMPTY_VALUE ? mah[i] : high[i];

      //
      //---
      //
         
      #define _max(_a,_b) ((_a)>(_b)?(_a):(_b))
      #define _min(_a,_b) ((_a)<(_b)?(_a):(_b))
      #define _abs(_a)    ((_a)>0.0?(_a):-(_a))
         
         double haClose = (!inpBetterFormula) ? (maOpen+maHigh+maLow+maClose)*0.25 : (maHigh!=maLow ? (maOpen+maClose)*0.5+(((maClose-maOpen)/(maHigh-maLow))*_abs((maClose-maOpen)*0.5)) : (maOpen+maClose)*0.5);
         double haOpen  = (i>0) ? (hao[i-1]+hac[i-1])*0.5 : (open[i]+close[i])*0.5;
         double haHigh  = _max(maHigh,_max(haOpen,haClose));
         double haLow   = _min(maLow, _min(haOpen,haClose));

         hal[i] = canl[i] = haLow;
         hah[i] = canh[i] = haHigh;
         hao[i] = cano[i] = haOpen;
         hac[i] = canc[i] = haClose;
         if(i>0)
         {
            if(_step>0)
            {
               if(_abs(hah[i]-hah[i-1]) < _step) hah[i]=hah[i-1];
               if(_abs(hal[i]-hal[i-1]) < _step) hal[i]=hal[i-1];
               if(_abs(hao[i]-hao[i-1]) < _step) hao[i]=hao[i-1];
               if(_abs(hac[i]-hac[i-1]) < _step) hac[i]=hac[i-1];
            }
            int acD = 0; if(acb[i]>acb[i-1]) acD=1; if(acb[i]<acb[i-1]) acD=2;
            int aoD = 0; if(aob[i]>aob[i-1]) aoD=1; if(aob[i]<aob[i-1]) aoD=2;

            cancl[i] = (acD==1 && aoD==1) ? 0 : (acD==2 && aoD==2) ? 1 : (acD==1 && aoD==2)? 2 : 3;
         }            
   }
   return(i);
}

//------------------------------------------------------------------
// custom functions
//------------------------------------------------------------------
//
//----
//

bool _checkHandle(int _handle, string _description)
{
   static int  _handles[];
          int  _size   = ArraySize(_handles);
          bool _answer = (_handle!=INVALID_HANDLE);
          if  (_answer)
               { ArrayResize(_handles,_size+1); _handles[_size]=_handle; }
          else { for (int i=_size-1; i>=0; i--) IndicatorRelease(_handles[i]); ArrayResize(_handles,0); Alert(_description+" initialization failed"); }
   return(_answer);
}  
//+------------------------------------------------------------------+
