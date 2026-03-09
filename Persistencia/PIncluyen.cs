using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.Data.SqlClient;
using System.Data;
using Entidades_Compartidas;

namespace Persistencia
{
    internal class PIncluyen
    {
        internal static void AltaIncluyen(Incluyen unIncluyen, int pCodigoPV, SqlTransaction miTRN)
        {
            SqlCommand _comando = new SqlCommand("AltaIncluyen", miTRN.Connection);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("codigoH", unIncluyen.Hospedaje.CodigoInterno);
            _comando.Parameters.AddWithValue("codigoPV", pCodigoPV);
            _comando.Parameters.AddWithValue("cantNoches", unIncluyen.CantNoches);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _comando.Transaction = miTRN;

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe el Hospedaje");
                if (_codRet == -2)
                    throw new Exception("No existe el Paquete Viaje");
                if (_codRet == -3)
                    throw new Exception("No se ha podido dar el alta! Ya existe un registro de ese Paquete Viaje con ese Hospedaje");
                if (_codRet == -4)
                    throw new Exception("No se ha podido dar el alta! Ha ocurrido un error con los datos ingresados");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        internal static List<Incluyen> ListarIncluyenDePV(int pCodigoPV, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Incluyen unIncluyen = null;
            List<Incluyen> listaIncluyen = new List<Incluyen>();

            SqlCommand _comando = new SqlCommand("ListarIncluyenDePV", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigoPV", pCodigoPV);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    while (_lector.Read())
                    {
                        unIncluyen = new Incluyen((int)_lector["cantNoches"], PHospedaje.GetInstancia().BuscarTodos((string)_lector["codigoH"], pLogueo));
                        listaIncluyen.Add(unIncluyen);
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                _cnn.Close();
            }
            return listaIncluyen;
        }
    }
}
