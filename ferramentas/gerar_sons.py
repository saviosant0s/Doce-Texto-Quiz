#!/usr/bin/env python3
"""Gera os efeitos sonoros do jogo por síntese (originais, sem direitos de
terceiros): moeda, estouro, porta, passo, pulo, construir e caixa.
Uso: ferramentas/gerar_sons.py  ->  godot/assets/sons/<nome>.wav"""
import os, wave
import numpy as np

TAXA = 22050
PASTA = os.path.join(os.path.dirname(__file__), "..", "godot", "assets", "sons")
rng = np.random.default_rng(7)


def t(dur):
    return np.arange(int(TAXA * dur)) / TAXA


def env(n, ataque=0.005, queda=10.0):
    x = np.arange(n) / TAXA
    a = np.clip(x / ataque, 0, 1)
    return a * np.exp(-x * queda)


def tom(freq, dur, queda=10.0, harm=(1.0, 0.3, 0.1)):
    x = t(dur)
    s = sum(h * np.sin(2 * np.pi * freq * (i + 1) * x) for i, h in enumerate(harm))
    return s * env(len(x), queda=queda)


def varredura(f0, f1, dur, queda=6.0):
    x = t(dur)
    f = np.linspace(f0, f1, len(x))
    fase = 2 * np.pi * np.cumsum(f) / TAXA
    return np.sin(fase) * env(len(x), queda=queda)


def ruido(dur, queda=20.0, suave=8):
    n = rng.standard_normal(int(TAXA * dur))
    n = np.convolve(n, np.ones(suave) / suave, mode="same")  # abafa (passa-baixa simples)
    return n * env(len(n), queda=queda)


def junta(*partes, espaco=0.0):
    saida = np.zeros(0)
    for p in partes:
        if len(saida):
            saida = np.concatenate([saida, np.zeros(int(TAXA * espaco))])
        saida = np.concatenate([saida, p])
    return saida


def mistura(*partes):
    n = max(len(p) for p in partes)
    s = np.zeros(n)
    for p in partes:
        s[: len(p)] += p
    return s


def salvar(nome, s, volume=0.8):
    s = s / (np.max(np.abs(s)) + 1e-9) * volume
    dados = (s * 32767).astype(np.int16)
    with wave.open(os.path.join(PASTA, nome + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(dados.tobytes())
    print(nome, f"{len(s) / TAXA:.2f}s")


# moeda: "plin-plin" agudo (si e mi)
salvar("moeda", junta(tom(988, 0.07, 30), tom(1319, 0.25, 12)), 0.6)
# estouro: bolha que sobe rápido + estalo
salvar("estouro", mistura(varredura(500, 1400, 0.09, 30), ruido(0.03, 120, 3) * 0.4), 0.7)
# porta: vento de abrir (ruído abafado subindo e descendo) + batidinha grave
x = t(0.45)
vento = rng.standard_normal(len(x))
vento = np.convolve(vento, np.ones(30) / 30, mode="same") * np.sin(np.pi * x / 0.45)
salvar("porta", mistura(vento * 0.8, tom(90, 0.15, 25, (1.0, 0.5)) * 0.8), 0.6)
# passo: batidinha macia
salvar("passo", mistura(tom(140, 0.07, 45, (1.0, 0.4)), ruido(0.05, 60, 12) * 0.5), 0.5)
# pulo: "bóing" subindo
salvar("pulo", varredura(260, 720, 0.16, 8), 0.6)
# construir: arpejo alegre (dó, mi, sol, dó)
salvar("construir", junta(*[tom(f, 0.09 if i < 3 else 0.35, 14 if i < 3 else 6) for i, f in enumerate([523, 659, 784, 1047])]), 0.6)
# caixa: "tchim" de caixa registradora (sininho + moedas)
salvar("caixa", mistura(tom(1568, 0.5, 6, (1.0, 0.2, 0.15, 0.1)), junta(np.zeros(int(TAXA * 0.06)), tom(1319, 0.2, 14)) * 0.6, ruido(0.08, 40, 2) * 0.2), 0.6)
# explosao: "bum" grave e fofo (peça especial explodindo no Doce Match)
salvar("explosao", mistura(tom(70, 0.45, 7, (1.0, 0.6, 0.3)), ruido(0.35, 9, 6) * 0.9, varredura(900, 200, 0.2, 12) * 0.3), 0.8)
# especial: brilho subindo (nasceu uma peça especial)
salvar("especial", mistura(varredura(700, 2100, 0.28, 5) * 0.6, junta(*[tom(f, 0.06, 20, (1.0, 0.2)) for f in [1319, 1568, 1976, 2637]]) * 0.5), 0.55)
# vitoria: fanfarra curta (sol, dó, mi, sol, dó agudo segurado)
salvar("vitoria", junta(*[tom(f, 0.1 if i < 4 else 0.6, 12 if i < 4 else 3, (1.0, 0.45, 0.2)) for i, f in enumerate([392, 523, 659, 784, 1047])]), 0.65)
