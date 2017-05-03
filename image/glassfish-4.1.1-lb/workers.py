#!/usr/bin/python3

import argparse
import binascii
import sys

class Workers:

	def __init__(self):
	
		self.__workers = {}
		
	def __encode_name(self, name):
	
		return "w{}".format(
			str(binascii.hexlify(name.encode("ascii")), "ascii")
		)
		
	def command_add(self, name, host, port):
	
		result = "start" if len(self.__workers) == 0 else "restart"
		self.__workers[self.__encode_name(name)] = {
			"type": "ajp13",
			"host": host,
			"port": port,
			"lbfactor": 1,
			"socket_keepalive": 1,
			"socket_timeout": 300
		}
		return result
		
	def command_remove(self, name):
	
		result = "restart" if len(self.__workers) > 1 else "stop"
		del self.__workers[self.__encode_name(name)]
		return result
		
	def load(self, workers_config_path, load_balancer_name):
	
		with open(workers_config_path, "r") as f:
			line = f.readline()
			if line.startswith("worker.list="):
				end_line_prefix = "worker.{}".format(load_balancer_name)
				line = f.readline()
				while not line.startswith(end_line_prefix):
					line = line.replace("worker.", "")
					index = line.index(".")
					worker_name = line[:index]
					worker_def = line[index + 1:-1]
					prop, value = worker_def.split("=")
					if worker_name not in self.__workers.keys():
						self.__workers[worker_name] = {}
					self.__workers[worker_name][prop] = value
					line = f.readline()
					
	def store(self, workers_config_path, load_balancer_name):
	
		with open(workers_config_path, "w") as f:
			if len(self.__workers) > 0:
				f.write("worker.list=")
				f.write(load_balancer_name)
				f.write(",jk-status,jk-manager")
				for worker_name, worker in self.__workers.items():
					for prop, value in worker.items():
						f.write("\nworker.")
						f.write(worker_name)
						f.write(".")
						f.write(prop)
						f.write("=")
						f.write(str(value))
				f.write("\nworker.")
				f.write(load_balancer_name)
				f.write(".type=lb")
				f.write("\nworker.")
				f.write(load_balancer_name)
				f.write(".balance_workers=")
				f.write(",".join(self.__workers.keys()))
				f.write("\nworker.")
				f.write(load_balancer_name)
				f.write(".sticky_session=true")
				f.write("\nworker.jk-status.type=status")
				f.write("\nworker.jk-manager.type=status")
				f.write("\n\n")
				
def workers_add(workers, command_args):

	parser = argparse.ArgumentParser(
		prog="{} ... add".format(sys.argv[0])
	)
	parser.add_argument(
		"name",
		metavar="name",
		type=str,
		nargs=1,
		help="worker name"
	)
	parser.add_argument(
		"host",
		metavar="host",
		type=str,
		nargs=1,
		help="worker host"
	)
	parser.add_argument(
		"port",
		metavar="port",
		type=str,
		nargs=1,
		help="worker port"
	)
	args = parser.parse_args(command_args)
	
	return workers.command_add(args.name[0], args.host[0], args.port[0])
	
def workers_remove(workers, command_args):

	parser = argparse.ArgumentParser(
		prog="{} ... remove".format(sys.argv[0])
	)
	parser.add_argument(
		"name",
		metavar="name",
		type=str,
		nargs=1,
		help="worker name"
	)
	args = parser.parse_args(command_args)
	
	return workers.command_remove(args.name[0])
	
def __main__():

	parser = argparse.ArgumentParser(
		prog=sys.argv[0]
	)
	parser.add_argument(
		"config_path",
		metavar="config_path",
		type=str,
		nargs=1,
		help="workers configuration file path"
	)
	parser.add_argument(
		"lb_name",
		metavar="lb_name",
		type=str,
		nargs=1,
		help="load balancer worker name"
	)
	parser.add_argument(
		"command",
		metavar="command",
		type=str,
		nargs=1,
		help="workers command"
	)
	parser.add_argument(
		"command_args",
		nargs=argparse.REMAINDER,
		help="workers command arguments"
	)
	args = parser.parse_args(sys.argv[1:])
	
	workers = Workers()
	workers.load(args.config_path[0], args.lb_name[0])
	workers_cmd = {
		"add": workers_add,
		"remove": workers_remove
	}
	sys.stdout.write(workers_cmd[args.command[0]](workers, args.command_args))
	workers.store(args.config_path[0], args.lb_name[0])
	
__main__()

