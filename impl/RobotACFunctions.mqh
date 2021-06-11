#include <Trade\Trade.mqh>

CTrade tradeLib;

#define LOW 0
#define HIGH 1
#define CLOSE 2
#define OPEN 3

enum OPERATOR{
   EQUAL,
   MAJOR,
   MINOR
};

enum ORIENTATION{
   UP,
   DOWN,
   MEDIUM
};

enum TYPE_NEGOCIATION{
   BUY,
   SELL,
   NONE
};

enum AVERAGE_PONTUATION{
   AVERAGE_0,
   AVERAGE_5,
   AVERAGE_10,
   AVERAGE_15,
   AVERAGE_20,
   AVERAGE_25,
   AVERAGE_30,
};

enum POWER{
   ON,
   OFF
};

enum COORDINATE{
   HORIZONTAL,
   VERTICAL
};


struct InfoDeal {
   double price;
   ulong ticket;
   datetime timeStartDeal;
};


struct ResultOperation {
   double total;
   double profits;
   double losses;
   double liquidResult;
   double profitFactor;
};

struct BordersOperation {
   double max;
   double min;
};

input POWER AGAINST_CURRENT = ON;
input POWER BASED_ON_FINANCIAL_PROFIT_AND_LOSS = ON;
input string NEGOCIATIONS_LIMIT_TIME = "17:30";
input string START_PROTECTION_TIME = "12:00";
input string END_PROTECTION_TIME = "13:00";
input double PROFIT_MAX_PER_DAY = 300;
input double LOSS_MAX_PER_DAY = 50;
input double TAKE_PROFIT = 100;
input double ACTIVE_VOLUME = 1;
input double STOP_LOSS = 10;
input int BARS_NUM = 4;
input int AVALIATION_TIME = 10;
input int HEGHT_BUTTON_PANIC = 350;
input int WIDTH_BUTTON_PANIC = 500;
input color INDICATOR_COLOR = clrRed;

MqlRates candles[];
MqlTick tick;

double takeProfit = (TAKE_PROFIT);
double stopLoss = (STOP_LOSS);

int count = 0;
MqlRates lastPriceSelected;
bool advanceDeal = false;
int pontuationEstimate;
datetime avaliationTime;
bool periodAchieved = false;
datetime dateClosedDeal;
InfoDeal infoDeal;
bool activeDeal = false;
TYPE_NEGOCIATION typeDeal = NONE;
bool startedAvaliationTime = false;
bool closedDeals = false;
bool isPossivelToSell = false;
int maxPositionsArray = 2;
BordersOperation borders;
bool waitNewPeriod = false;
double profits = 0;
double losses = 0;

ResultOperation resultDeals;

void startRobots(){
  printf("Start Robots in " +  _Symbol);
  //CopyRates(_Symbol,_Period,0,maxPositionsArray,candles);
  //ArraySetAsSeries(candles, true);
  createButton("BotaoPanic", WIDTH_BUTTON_PANIC, HEGHT_BUTTON_PANIC, 200, 30, CORNER_LEFT_LOWER, 12, "Calibri", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
  Print("Negociações Abertas para o dia: ", TimeToString(TimeCurrent(), TIME_DATE));
}

void finishRobots(){
  printf("Finish Robots in " +  _Symbol);
}

void closeBuyOrSell(){
   ulong ticket = PositionGetTicket(0);
   tradeLib.PositionClose(ticket);
   verifyResultTrade();
}

void decideToBuyOrSell(ORIENTATION orient){
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = SELL;
   }else if(orient == DOWN){
      typeDeal = BUY;
   }else{
      typeDeal = NONE;
   }
   
   /**/
   
   if(AGAINST_CURRENT == ON){
      if(typeDeal == BUY){
         typeDeal = SELL;            
      }
      else if(typeDeal == SELL){
         typeDeal = BUY;
      }
   }
   
   realizeDeals(typeDeal);
   getHistory();
}

ORIENTATION verifyOrientation(){
   if(hasNewCandle()){
      int numBars = SeriesInfoInteger(Symbol(),Period(),SERIES_BARS_COUNT);
      if(numBars % BARS_NUM == 0) {
         waitNewPeriod = false;
         int barsPrevActualCandle = BARS_NUM - 1;
         int copied = CopyRates(_Symbol,_Period,0, BARS_NUM, candles);
         if(copied == BARS_NUM && barsPrevActualCandle > 0){
            int up = 0, down = 0;
            MqlRates lastCandle = candles[barsPrevActualCandle], prevCandle, nextCandle;
            double maxPrice = candles[0].high, minPrice = candles[0].low;
            double prevHigh = 0, prevLow = 0, nextHigh = 0, nextLow = 0;
            for(int i = 0; i < barsPrevActualCandle; i++){
               prevCandle = candles[i];
               nextCandle = candles[i+1];
               
               if(prevCandle.open > prevCandle.close){
                  prevHigh = prevCandle.open;
                  prevLow = prevCandle.close;
               }else{
                  prevLow = prevCandle.open;
                  prevHigh = prevCandle.close;
               }
               
               if(nextCandle.open > nextCandle.close){
                  nextHigh = nextCandle.open;
                  nextLow = nextCandle.close;
               }else{
                  nextLow = nextCandle.open;
                  nextHigh = nextCandle.close;
               }
               
               //O sinal está subindo
               if(prevHigh <= nextHigh && prevLow <= nextLow){
                  up++;
               }
               
               //O sinal está descendo
               if(prevHigh >= nextHigh && prevLow >= nextLow){
                  down++;
               }
               
               if(prevCandle.high > maxPrice){
                  maxPrice = prevCandle.high;
               }
               
               if(prevCandle.low < minPrice){
                  minPrice = prevCandle.low;
               }
            }
            
            datetime actualTime = TimeLocal();
            int medium = barsPrevActualCandle / 2;
            if(up > medium){ 
               drawVerticalLine(actualTime, "up" + numBars, clrYellow);
               lastPriceSelected = lastCandle;
               return UP;
            }else if(down > medium){
               drawVerticalLine(actualTime, "down" + numBars, clrGreen);
               lastPriceSelected = lastCandle;
               return DOWN;
            }else{
               return MEDIUM;
            }
         }
      }else{
         if(lastPriceSelected.close > 0 && waitNewPeriod == false){
            /* verifica se existe posicao aberta e qual tipo de tipo de posicao esta ativo*/
            if(PositionSelect(_Symbol) == true){
                MqlRates precos[1];
               int copiedPrice = CopyRates(_Symbol,_Period,0,1,precos);
               if(copiedPrice == 1){
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                     closeBuyOrSell();
                     if(lastPriceSelected.close >= precos[0].close){
                        waitNewPeriod = true;
                        return DOWN;
                     }
                  }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                     closeBuyOrSell();
                     if(lastPriceSelected.close >= precos[0].close){
                        waitNewPeriod = true;
                        return UP;
                     }
                  }
               }
            }
         }
      }
   }
   
   return MEDIUM;
}

void toBuy(MqlTick& tick){
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized);
}

void toSell(MqlTick& tick){
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(ACTIVE_VOLUME, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);
}

void normalizeTakeProfitAndStopLoss(){
   // modificação para o indice dolar DOLAR_INDEX
   if(STOP_LOSS != 0 || TAKE_PROFIT != 0){
      if(_Digits == 3){
         stopLoss = (STOP_LOSS * 1000);
         takeProfit = (TAKE_PROFIT * 1000);  
      }else{
         stopLoss = NormalizeDouble((STOP_LOSS * _Point), _Digits);
         takeProfit = NormalizeDouble((TAKE_PROFIT * _Point), _Digits); 
      }
   }
}

void realizeDeals(TYPE_NEGOCIATION typeDeal){
   if(typeDeal != NONE){
      normalizeTakeProfitAndStopLoss();   
      if(PositionSelect(_Symbol) == false) {
         //Instanciar TICKS
         SymbolInfoTick(_Symbol, tick);
         if(typeDeal == BUY){
            toBuy(tick);
         }
         else if(typeDeal == SELL){
            toSell(tick);
         }
         
         if(verifyResultTrade()){
            //Salvar informacoes da negociação iniciado
            infoDeal.price = PositionGetDouble(POSITION_PRICE_CURRENT);
            infoDeal.ticket = PositionGetTicket(0);
            infoDeal.timeStartDeal = TimeLocal();
         }
       }
    }
 }

ResultOperation getResultOperation(double result){
   ResultOperation resultOperation;
   resultOperation.total = 0;
   resultOperation.losses = 0;
   resultOperation.profits = 0;
   resultOperation.liquidResult = 0;
   resultOperation.profitFactor = 0;
   
   resultOperation.total += result; 
   
   if(result > 0){
      resultOperation.profits += result;
   }
   
   if(result < 0){
      resultOperation.losses += (-result);
   }
   
   resultOperation.liquidResult = resultOperation.profits - resultOperation.losses;
   //Definir fator de lucro
   if(resultOperation.losses > 0){
      resultOperation.profitFactor = resultOperation.profits / resultOperation.losses;
   }else{
      resultOperation.profitFactor = -1;
   }
   
   return resultOperation;
}

void getHistory(){
   ResultOperation resultOperation, resultOp;
   double result = 0;
   
   HistorySelect(0, TimeCurrent());
   ulong trades = HistoryDealsTotal();
   Print("Total de negociações: ", trades);
   
   for(int i = 1; i <= trades; i++)  {
      ulong tick_n = HistoryDealGetTicket(i);
      result = HistoryDealGetDouble(tick_n,DEAL_PROFIT);    
      resultOp = getResultOperation(result);
      resultOperation.total += resultOp.total;
      resultOperation.losses += resultOp.losses;
      resultOperation.profits += resultOp.profits;
      resultOperation.liquidResult += resultOp.liquidResult;
      resultOperation.profitFactor += resultOp.profitFactor;  
   }
   
   Print("Lucro Atual: R$ ", resultOperation.liquidResult);
   if(resultOperation.liquidResult >= PROFIT_MAX_PER_DAY || resultOperation.liquidResult <= -LOSS_MAX_PER_DAY ) {
     Print("Limite atingido por dia -> R$ ", resultOperation.liquidResult);
     toCloseDeals();
   }     
       
   Comment("Trades: " + IntegerToString(trades), 
   " Profits: " + DoubleToString(resultOperation.profits, 2), 
   " Losses: " + DoubleToString(resultOperation.losses, 2), 
   " Profit Factor: " + DoubleToString(resultOperation.profitFactor, 2), 
   " Liquid Result: " + DoubleToString(resultOperation.liquidResult, 2));
}

bool verifyResultTrade(){
   if(tradeLib.ResultRetcode() == TRADE_RETCODE_PLACED || tradeLib.ResultRetcode() == TRADE_RETCODE_DONE){
      printf("Ordem de %s executada com sucesso.");
      return true;
   }else{
      Print("Erro de execução de ordem ", GetLastError());
      ResetLastError();
      return false;
   }
}

bool timeToProtection(string protectionTime, OPERATOR oper){
   string actualTime = TimeToString(TimeCurrent(),TIME_MINUTES);
   
   if(protectionTime == "00:00"){
      return false;
   }else{
      if(oper == MINOR){
         if(actualTime <= protectionTime){
            return true;
         }
      }
      if(oper == MAJOR){
         if(actualTime >= protectionTime){
            return true;
         }
      }else{
         if(actualTime == protectionTime){
            return true;
         }
      }
   }
   
   return false;
}

void toCloseDeals(){
   dateClosedDeal = TimeLocal();
   closedDeals = true;
}

void startDeals(){
   if(timeToProtection(START_PROTECTION_TIME, MAJOR) && timeToProtection(END_PROTECTION_TIME, MINOR)){
      //printf("Horario de proteção ativo");
   }else if(timeToProtection(NEGOCIATIONS_LIMIT_TIME, MAJOR) ){
      Print("Fim do tempo operacional. Encerrando Negociações");
      toCloseDeals();
   }else{
      ORIENTATION orient = verifyOrientation();
      decideToBuyOrSell(orient);    
   }
}

void drawHorizontalLine(double price, string nameLine, color indColor){
   ObjectCreate(_Symbol,nameLine,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(_Symbol,nameLine,0,0,price);
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(_Symbol,nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, int fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   ObjectCreate(_Symbol,nameLine,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,nameLine,OBJPROP_XDISTANCE,xx);
   ObjectSetInteger(0,nameLine,OBJPROP_YDISTANCE, yy);
   ObjectSetInteger(0,nameLine,OBJPROP_XSIZE, largura);
   ObjectSetInteger(0,nameLine,OBJPROP_YSIZE, altura);
   ObjectSetInteger(0,nameLine,OBJPROP_CORNER, canto);
   ObjectSetInteger(0,nameLine,OBJPROP_FONTSIZE, tamanho);
   ObjectSetString(0,nameLine,OBJPROP_FONT, fonte);
   ObjectSetString(0,nameLine,OBJPROP_TEXT, text);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR, corTexto);
   ObjectSetInteger(0,nameLine,OBJPROP_BGCOLOR, corFundo);
   ObjectSetInteger(0,nameLine,OBJPROP_BORDER_COLOR, corBorda);
}


bool hasNewCandle(){
   static datetime lastTime = 0;
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   
   //primeira chamada da funcao
   if(lastTime == 0){
      lastTime = lastBarTime;
      return false;
   }
   
   if(lastTime != lastBarTime){
      lastTime = lastBarTime;
      return true;
   }
   
   return false;
}

void removeDeals(){
   Print("Removendo negociações..");
   Print("Posições em aberto: ", PositionsTotal());
   while(PositionsTotal() > 0){
      Print("Posições em aberto: ", PositionsTotal());
      closeBuyOrSell();
   }
   
   toCloseDeals();
}
