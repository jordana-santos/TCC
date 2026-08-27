//regras de negocio isoladas
//aplica >uma< regra (por exemplo bloquear se o evento estiver lotado) antes de chamar o repository
//se usa quando tem uma regra especifica

import Foundation

enum EventError: Error {
    case full
    case mustBeGoingToCheckIn
    case capacityBelowAttendees
}
