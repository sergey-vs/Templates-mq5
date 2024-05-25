//+------------------------------------------------------------------+
//|                                               GraphicalPanel.mqh |
//|                                                  Sergey_s_altaya |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Sergey_s_altaya"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== Panel Inputs ====";
static input int InpPanelWidth = 260;                       // width in pixel (ширина в пикселях)
static input int InpPanelHeight = 230;                      // height in pixel (высота в пикселях)
static input int InpPanelFontSize = 13;                     // font size (размер шрифта)
static input color InpPanelTxtColor = clrWhiteSmoke;      // text color  (цвет текста)

//+------------------------------------------------------------------+
//| Class CGraphicalPanel                                            |
//+------------------------------------------------------------------+
class CGraphicalPanel : public CAppDialog
(

);