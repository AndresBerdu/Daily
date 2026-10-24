class_name UserBank
extends RefCounted

# Normales: creados entre 2019 y 2025
const NORMAL := [
	["Laura Gomez", "laura.gomez@oficina.com", "2019-03-14"],
	["Carlos Ramirez", "carlos.ramirez@oficina.com", "2019-07-22"],
	["Andrea Velez", "andrea.velez@oficina.com", "2020-01-09"],
	["Julian Restrepo", "julian.restrepo@oficina.com", "2020-05-30"],
	["Marta Ospina", "marta.ospina@oficina.com", "2020-09-12"],
	["Sebastian Cano", "sebastian.cano@oficina.com", "2020-11-03"],
	["Valentina Zapata", "valentina.zapata@oficina.com", "2021-02-18"],
	["Daniel Arango", "daniel.arango@oficina.com", "2021-04-27"],
	["Camila Herrera", "camila.herrera@oficina.com", "2021-06-15"],
	["Mateo Giraldo", "mateo.giraldo@oficina.com", "2021-08-08"],
	["Sofia Montoya", "sofia.montoya@oficina.com", "2021-10-21"],
	["Santiago Duque", "santiago.duque@oficina.com", "2021-12-05"],
	["Isabela Londono", "isabela.londono@oficina.com", "2022-01-19"],
	["Felipe Mejia", "felipe.mejia@oficina.com", "2022-03-11"],
	["Natalia Cardona", "natalia.cardona@oficina.com", "2022-05-24"],
	["Andres Salazar", "andres.salazar@oficina.com", "2022-07-07"],
	["Paula Escobar", "paula.escobar@oficina.com", "2022-09-16"],
	["Tomas Alvarez", "tomas.alvarez@oficina.com", "2022-11-29"],
	["Daniela Ruiz", "daniela.ruiz@oficina.com", "2023-01-13"],
	["Esteban Pineda", "esteban.pineda@oficina.com", "2023-03-06"],
	["Lucia Marin", "lucia.marin@oficina.com", "2023-04-20"],
	["Nicolas Builes", "nicolas.builes@oficina.com", "2023-06-02"],
	["Mariana Tobon", "mariana.tobon@oficina.com", "2023-08-25"],
	["Juan Pablo Correa", "juan.correa@oficina.com", "2023-10-10"],
	["Catalina Rojas", "catalina.rojas@oficina.com", "2024-01-17"],
	["Gabriel Yepes", "gabriel.yepes@oficina.com", "2024-03-28"],
	["Manuela Franco", "manuela.franco@oficina.com", "2024-06-14"],
	["Samuel Bedoya", "samuel.bedoya@oficina.com", "2024-09-03"],
	["Emilia Cardenas", "emilia.cardenas@oficina.com", "2025-02-12"],
	["Alejandro Munoz", "alejandro.munoz@oficina.com", "2025-05-19"],
]

# Intrusos: creados en los ultimos 7 dias (2026-10-18 a 2026-10-24)
const INTRUDERS := [
	["guest_4821", "guest4821@mailnow.xyz", "2026-10-24"],
	["admin_root", "admin.root@tempbox.ru", "2026-10-23"],
	["test_user01", "test01@fastmail.top", "2026-10-24"],
	["x_l0ader", "xl0ader@darkmx.cc", "2026-10-22"],
	["backup_svc", "backup.svc@proxy-net.biz", "2026-10-23"],
	["temp_9917", "temp9917@10minmail.io", "2026-10-21"],
	["support_help", "help.support@secure-login.co", "2026-10-24"],
	["unknown_k3", "k3@anon.mail", "2026-10-20"],
	["sys_update", "sys.update@patch-now.net", "2026-10-22"],
	["user_x88", "x88@throwaway.org", "2026-10-19"],
	["root_login", "rootlogin@proxy-net.biz", "2026-10-23"],
	["data_miner", "miner@darkmx.cc", "2026-10-24"],
	["guest_0073", "guest0073@mailnow.xyz", "2026-10-18"],
	["net_probe", "probe@scan-net.top", "2026-10-21"],
	["svc_admin2", "svc2@tempbox.ru", "2026-10-22"],
]

static func get_all() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	
	for u in NORMAL:
		all.append({"name": u[0], "email": u[1], "created": u[2], "intruder": false})
	for u in INTRUDERS:
		all.append({"name": u[0], "email": u[1], "created": u[2], "intruder": true})
	return all
