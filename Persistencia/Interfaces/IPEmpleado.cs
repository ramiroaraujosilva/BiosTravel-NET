using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;

namespace Persistencia.Interfaces
{
    public interface IPEmpleado
    {
        void NuevoUsuario(Empleados unEmpleado, Empleados pLogueo);
        void Modificar(Empleados unEmpleado, Empleados pLogueo);
        Empleados Logueo(string pUsuario, string pPassUsu);
        Empleados Buscar(string pUsuario, Empleados pLogueo);
        List<Empleados> Listar(Empleados pLogueo);
    }
}
