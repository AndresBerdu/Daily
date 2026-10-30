class_name UiLayer
extends RefCounted
## Orden de dibujado de las capas de UI (mayor = mas arriba).
## Si agregas una capa nueva, defínela aqui para no repetir numeros por todo el proyecto.

const HUD := 1
const MENU := 90            # menu de pausa
const SUBMENU := 95         # cargar partida y opciones, encima del menu que los abrio
const GAME_OVER := 98
const TRANSITION := 100     # SceneTransition (siempre arriba)
