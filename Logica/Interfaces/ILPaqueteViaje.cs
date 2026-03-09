using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;

namespace Logica.Interfaces
{
    public interface ILPaqueteViaje
    {
        void Alta(PaquetesViajes unPaqueteViaje, Empleados pLogueo);
        PaquetesViajes Buscar(string pCodigo, Empleados pLogueo);
        List<PaquetesViajes> Listar(Empleados pLogueo);
        List<PaquetesViajes> ListarPaquetesViajesPorHospedaje(Hospedajes pHospedajes, Empleados pLogueo);
    }
}
