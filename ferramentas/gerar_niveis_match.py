"""Gera godot/dados/doce_match.json (os 30 níveis do Doce Match).
Uso (dentro de godot/): python3 ../ferramentas/gerar_niveis_match.py ../ferramentas/doce_match_estrelas.json
Depois de mudar o plano, rode o robô de calibragem (godot/testes/calibrar_doce_match.tscn)
e ajuste jogadas (MAIS) e estrelas (doce_match_estrelas.json: pontos para 1, 2 e 3 estrelas)."""
import json,sys
G={
 "centro":["........","........","..gggg..","..gggg..","..gggg..","..gggg..","........","........"],
 "faixa":["........","........","........","gggggggg","gggggggg","........","........","........"],
 "cantos":["gg....gg","g......g","........","........","........","........","g......g","gg....gg"],
 "xis":["g......g",".g....g.","..g..g..","...gg...","...gg...","..g..g..",".g....g.","g......g"],
 "moldura":["gggggggg","g......g","g......g","g......g","g......g","g......g","g......g","gggggggg"],
 "baixo":["........","........","........","........","gggggggg","gggggggg","gggggggg","gggggggg"],
 "tudo":["gggggggg"]*8,
 "coracao":[".gg..gg.","gggggggg","gggggggg","gggggggg",".gggggg.","..gggg..","...gg...","........"],
}
# (tipo, jogadas, tipos, parametro, desenho)
plano=[
 ("pontos",15,5,1500,None),("pontos",15,5,2500,None),("coletar",15,5,("planilha",15),None),
 ("gelatina",16,5,None,"centro"),("pontos",14,5,4000,None),
 ("coletar",20,6,("folha",20),None),("gelatina",24,6,None,"faixa"),("misto",20,6,(("grafico",15),3000),None),
 ("gelatina",30,6,None,"cantos"),("coletar2",19,6,(("celula",14),("tecla",14)),None),
 ("pontos",16,6,4400,None),("gelatina",33,6,None,"xis"),("misto_g",24,6,("disquete",15),"centro"),
 ("coletar",21,6,("planilha",28),None),("gelatina",38,6,None,"moldura"),
 ("pontos",15,6,4800,None),("coletar2",22,6,(("folha",18),("grafico",18)),None),("gelatina",31,6,None,"baixo"),
 ("misto",22,6,(("tecla",22),5000),None),("gelatina",30,6,None,"coracao"),
 ("misto_g",24,6,("celula",20),"faixa"),("pontos",16,6,4200,None),("coletar",22,6,("disquete",26),None),
 ("gelatina",34,6,None,"tudo"),("coletar2",22,6,(("planilha",22),("folha",22)),None),
 ("misto_g",35,6,("grafico",22),"cantos"),("pontos",15,6,4600,None),("gelatina",30,6,None,"xis"),
 ("misto_g",36,6,("tecla",20),"moldura"),("misto_g",28,6,("planilha",26),"coracao"),
]
esc={}
MAIS={9:2,11:2,12:2,15:2,16:2,18:7,20:2,23:2,24:8,26:2,29:2,30:2,14:1,22:1,27:2}
est=json.load(open(sys.argv[1])) if len(sys.argv)>1 else {}
niveis=[]
for i,(tipo,jog,tipos,par,des) in enumerate(plano):
    n=i+1; f=esc.get(str(n),1.0); jog+=MAIS.get(n,0)
    objs=[]
    if tipo=="pontos": objs=[{"tipo":"pontos","meta":int(round(par*f/50)*50)}]
    elif tipo=="coletar": objs=[{"tipo":"coletar","peca":par[0],"quantidade":max(5,int(round(par[1]*f)))}]
    elif tipo=="coletar2": objs=[{"tipo":"coletar","peca":p,"quantidade":max(5,int(round(q*f)))} for p,q in par]
    elif tipo=="gelatina": objs=[{"tipo":"gelatina"}]
    elif tipo=="misto": objs=[{"tipo":"coletar","peca":par[0][0],"quantidade":max(5,int(round(par[0][1]*f)))},{"tipo":"pontos","meta":int(round(par[1]*f/50)*50)}]
    elif tipo=="misto_g": objs=[{"tipo":"gelatina"},{"tipo":"coletar","peca":par[0],"quantidade":max(5,int(round(par[1]*f)))}]
    d={"numero":n,"jogadas":jog,"tipos":tipos,"objetivos":objs,"estrelas":est.get(str(n),[0,0,0])}
    if des: d["gelatina"]=G[des]
    niveis.append(d)
json.dump({"_comentario":"Níveis do Doce Match (ver scripts/doce_match.gd). objetivos: pontos (meta), coletar (peca, quantidade), gelatina (limpar toda a camada 'g' do desenho). estrelas: pontos para 1, 2 e 3 estrelas (vencer vale ao menos 1). Calibrados com um robô que joga guloso (testes/calibrar_doce_match.gd).","niveis":niveis},open('dados/doce_match.json','w'),ensure_ascii=False,indent=1)
print(len(niveis))
