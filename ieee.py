import struct

# Solicita al usuario un número decimal y lo convierte a float
numero = float(input("Ingresa un número decimal: "))

# Convierte el número a formato IEEE 754 de 32 bits y lo muestra en hexadecimal
hex_ieee = hex(struct.unpack('>I', struct.pack('>f', numero))[0])
print(f"Representación IEEE 754 en hexadecimal: {hex_ieee}")


