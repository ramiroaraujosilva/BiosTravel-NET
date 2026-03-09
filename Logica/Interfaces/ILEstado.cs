using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;

namespace Logica.Interfaces
{
    public interface ILEstado
    {
        void Alta(Estados unEstado, Empleados pLogueo);
        void Eliminar(Estados unEstado, Empleados pLogueo);
        void Modificar(Estados unEstado, Empleados pLogueo);
        Estados Buscar(string pCodigo, Empleados pLogueo);
        List<Estados> Listar(Empleados pLogueo);
    }
}
