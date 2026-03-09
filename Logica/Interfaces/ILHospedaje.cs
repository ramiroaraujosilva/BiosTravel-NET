using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;

namespace Logica.Interfaces
{
    public interface ILHospedaje
    {
        void Alta(Hospedajes unHospedaje, Empleados pLogueo);
        void Eliminar(Hospedajes unHospedaje, Empleados pLogueo);
        void Modificar(Hospedajes unHospedaje, Empleados pLogueo);
        Hospedajes Buscar(string pCodigo, Empleados pLogueo);
        List<Hospedajes> Listar(Empleados pLogueo);
    }
}
