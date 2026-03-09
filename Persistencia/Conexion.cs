using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;

namespace Persistencia
{
    internal class Conexion
    {
        internal static string Cnn(Empleados unEmpleado = null)
        {
            if (unEmpleado == null)
                return "Data Source =.; Initial Catalog = BiosTravel; Integrated Security = true";
            else
                return "Data Source =.; Initial Catalog = BiosTravel; User=" + unEmpleado.Usuario + "; Password='" + unEmpleado.PassUsu + "'";

        }
    }
}
