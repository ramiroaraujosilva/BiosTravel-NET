using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;

namespace Persistencia.Interfaces
{
    public interface IPVuelo
    {
        void Alta(Vuelos unVuelo, Empleados pLogueo);
        void Eliminar(Vuelos unVuelo, Empleados pLogueo);
        void Modificar(Vuelos unVuelo, Empleados pLogueo);
        Vuelos Buscar(string pCodigo, Empleados pLogueo);
        List<Vuelos> Listar(Empleados pLogueo);
    }
}
